"""Shared API and static Flutter host for the Toidym pilot."""

import argparse
import base64
import hashlib
import hmac
import json
import logging
import math
import os
import re
import secrets
import sqlite3
from contextlib import closing, contextmanager
from datetime import UTC, datetime, timedelta, timezone
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urlsplit
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent
ASTANA = timezone(timedelta(hours=5))
DEMO_CODE = '4821'
DEMO_ADMIN = '+77000000001'
DEMO_OWNER = '+77000000002'
DEMO_CASHIER = '+77000000003'
PHONE = re.compile(r'\+7[0-9]{10}')
DEMO_PHONE = re.compile(r'\+770000000[0-9]{2}')
PICKUP = re.compile(r'(?:[0-9]{4}|[a-f0-9]{32})')
KEY = re.compile(r'[a-zA-Z0-9_-]{12,80}')


class ApiError(Exception):
    def __init__(self, status, code):
        self.status = status
        self.code = code


def now():
    return int(datetime.now(UTC).timestamp())


def iso(seconds):
    return datetime.fromtimestamp(seconds, UTC).isoformat() if seconds else None


def digest(value):
    return hashlib.sha256(value.encode()).hexdigest()


@contextmanager
def write(db):
    db.execute('BEGIN IMMEDIATE')
    try:
        yield
        db.commit()
    except BaseException:
        db.rollback()
        raise


def phone_value(value):
    if not isinstance(value, str) or not PHONE.fullmatch(value):
        raise ApiError(400, 'invalid_phone')
    return value


def string(body, field, limit, minimum=1):
    value = body.get(field)
    if not isinstance(value, str) or not minimum <= len(value.strip()) <= limit:
        raise ApiError(400, 'invalid_input')
    return value.strip()


def integer(body, field, minimum, maximum):
    value = body.get(field)
    if type(value) is not int or not minimum <= value <= maximum:
        raise ApiError(400, 'invalid_input')
    return value


def number(body, field, minimum, maximum):
    value = body.get(field)
    if type(value) not in (int, float) or not math.isfinite(value) or not minimum <= value <= maximum:
        raise ApiError(400, 'invalid_input')
    return value


def record(db, phone, action, target, note=''):
    db.execute('INSERT INTO audit(occurred,actor,action,target,note) VALUES(?,?,?,?,?)',
               (now(), phone, action, target, note))


def venue_for(db, phone):
    return db.execute('''
        SELECT v.*, 'owner' AS role FROM venues v WHERE v.owner=?
        UNION ALL
        SELECT v.*, 'cashier' AS role FROM venues v JOIN staff s ON s.venue_id=v.id WHERE s.phone=?
    ''', (phone, phone)).fetchone()


def require_venue(db, phone, owner=False):
    venue = venue_for(db, phone)
    if not venue or venue['status'] != 'approved' or owner and venue['role'] != 'owner':
        raise ApiError(403, 'forbidden')
    return venue


def box_json(row, current):
    result = json.loads(row['details'])
    result.update(id=row['id'], stock=row['stock'],
                  published=bool(row['published'] and not row['paused'] and row['ends'] > current),
                  pickupStart=iso(row['starts']), pickupEnd=iso(row['ends']))
    return result


def order_json(row, viewer):
    buyer = row['buyer'] == viewer
    return dict(id=row['id'], owner=viewer if buyer else '', box=json.loads(row['snapshot']),
                code=row['code'] if buyer else '', qr=row['qr'] if buyer else '',
                quantity=row['quantity'], created=iso(row['created']),
                status='expired' if row['status']=='reserved' and row['ends']<=now() else row['status'],
                collectedAt=iso(row['collected']), rating=row['rating'], feedback=json.loads(row['feedback']),
                issue=row['issue'] if buyer else '', resolution=row['resolution'] if buyer else '')


def expire_orders(db, current):
    db.execute("UPDATE orders SET status='expired' WHERE status='reserved' AND ends <= ?", (current,))


class Pilot:
    def __init__(self, db_path, demo, admins, web_root):
        self.path = db_path
        self.demo = demo
        self.admins = {DEMO_ADMIN} if demo else admins
        self.web_root = web_root
        self.verify = tuple(os.environ.get(k, '') for k in
                            ('TWILIO_ACCOUNT_SID', 'TWILIO_AUTH_TOKEN', 'TWILIO_VERIFY_SERVICE_SID'))
        if not demo and not all(self.verify):
            raise ValueError('Set Twilio Verify credentials or use --demo on loopback.')
        db_path.parent.mkdir(parents=True, exist_ok=True)
        with closing(self.connect()) as db:
            db.executescript((ROOT / 'schema.sql').read_text(encoding='utf-8'))
            if demo:
                self.seed(db)

    def connect(self):
        db = sqlite3.connect(self.path, timeout=5, isolation_level=None)
        db.row_factory = sqlite3.Row
        db.execute('PRAGMA foreign_keys = ON')
        return db

    def seed(self, db):
        with write(db):
            venue = 'demo-bakery'
            db.execute('''INSERT OR IGNORE INTO venues
                (id,owner,name,company,address,district,lat,lng,status)
                VALUES(?,?,?,?,?,?,?,?,?)''',
                (venue, DEMO_OWNER, 'Таңғы нан', 'Таңғы нан', 'Сығанақ, 16', 0, 51.1213, 71.4175, 'approved'))
            db.execute('INSERT OR IGNORE INTO staff(phone,venue_id) VALUES(?,?)', (DEMO_CASHIER, venue))
            current = datetime.now(ASTANA)
            day = current.date().isoformat()
            existing = db.execute('SELECT 1 FROM boxes WHERE id=?', ('demo-bread-' + day,)).fetchone()
            if not existing:
                self.insert_box(db, venue_for(db, DEMO_OWNER), 'demo-bread-' + day, dict(
                    kk='Кешкі нан боксы', ru='Вечерний хлебный бокс', category='bakery',
                    description='Нан және тоқаштар. Аллергендер / аллергены: бидай / пшеница.',
                    price=1490, original=4500, stock=4, day=day, window='00:00–23:59',
                ), demo_seed=True)

    def limit(self, db, scope, maximum, seconds):
        current = now()
        count = db.execute('SELECT COUNT(*) FROM auth_limits WHERE scope=? AND occurred>?',
                           (scope, current-seconds)).fetchone()[0]
        if count >= maximum:
            raise ApiError(429, 'rate_limit')
        db.execute('INSERT INTO auth_limits VALUES(?,?)', (scope, current))
        db.execute('DELETE FROM auth_limits WHERE occurred <= ?', (current-3600,))

    def twilio(self, resource, form):
        account, token, service = self.verify
        auth = base64.b64encode(f'{account}:{token}'.encode()).decode()
        request = Request(f'https://verify.twilio.com/v2/Services/{service}/{resource}',
                          data=urlencode(form).encode(), headers={
                              'Authorization': 'Basic ' + auth,
                              'Content-Type': 'application/x-www-form-urlencoded',
                          })
        try:
            with urlopen(request, timeout=8) as response:
                return json.load(response)
        except HTTPError as error:
            if resource == 'VerificationCheck' and error.code in (400, 404):
                return {'status': 'denied'}
            if error.code == 429:
                raise ApiError(429, 'rate_limit') from None
            raise ApiError(503, 'sms_unavailable') from None
        except (URLError, TimeoutError):
            raise ApiError(503, 'sms_unavailable') from None

    def request_code(self, db, body, ip):
        phone = phone_value(body.get('phone'))
        if self.demo and not DEMO_PHONE.fullmatch(phone):
            raise ApiError(400, 'demo_phone')
        with write(db):
            self.limit(db, 'send:ip:' + ip, 20, 3600)
            self.limit(db, 'send:phone:' + phone, 4, 3600)
        if not self.demo:
            self.twilio('Verifications', {'To': phone, 'Channel': 'sms'})
        db.execute('REPLACE INTO challenges VALUES(?,?,0)', (phone, now()+300))
        return {'demo': self.demo}

    def verify_code(self, db, body, ip):
        phone = phone_value(body.get('phone'))
        code = string(body, 'code', 10)
        if not re.fullmatch(r'[0-9]{4,10}', code):
            raise ApiError(400, 'invalid_code')
        with write(db):
            self.limit(db, 'check:ip:' + ip, 40, 3600)
            challenge = db.execute('SELECT * FROM challenges WHERE phone=?', (phone,)).fetchone()
            if not challenge or challenge['expires'] <= now() or challenge['attempts'] >= 5:
                raise ApiError(401, 'invalid_code')
            db.execute('UPDATE challenges SET attempts=attempts+1 WHERE phone=?', (phone,))
        approved = hmac.compare_digest(code, DEMO_CODE) if self.demo else (
            self.twilio('VerificationCheck', {'To': phone, 'Code': code})['status'] == 'approved')
        if not approved:
            raise ApiError(401, 'invalid_code')
        token = secrets.token_urlsafe(32)
        with write(db):
            removed = db.execute('DELETE FROM challenges WHERE phone=? AND expires=? AND expires>?',
                                 (phone, challenge['expires'], now())).rowcount
            if not removed:
                raise ApiError(401, 'invalid_code')
            db.execute('DELETE FROM sessions WHERE expires <= ?', (now(),))
            db.execute('INSERT INTO sessions VALUES(?,?,?)', (digest(token), phone, now()+86400))
        return {'token': token}

    def state(self, db, phone):
        current = now()
        venue = venue_for(db, phone)
        venue_id = venue['id'] if venue else ''
        owned = venue_id if venue and venue['role'] == 'owner' and venue['status'] == 'approved' else ''
        public = db.execute('''
            SELECT b.* FROM boxes b JOIN venues v ON v.id=b.venue_id
            WHERE v.status='approved' AND b.ends>? AND b.published=1 AND b.paused=0
            ORDER BY b.starts,b.id
        ''', (current,)).fetchall()
        inventory = db.execute('SELECT * FROM boxes WHERE venue_id=? ORDER BY starts DESC,id',
                               (owned,)).fetchall() if owned else []
        buyer = db.execute('SELECT * FROM orders WHERE buyer=? ORDER BY created DESC,id', (phone,)).fetchall()
        branch = db.execute('SELECT * FROM orders WHERE venue_id=? ORDER BY created DESC,id',
                            (venue_id,)).fetchall() if venue and venue['status'] == 'approved' else []
        staff = db.execute('SELECT phone FROM staff WHERE venue_id=? ORDER BY phone', (owned,)).fetchall() if owned else []
        branch_fields = ('name', 'address', 'district', 'status', 'role', 'review_note')
        return dict(demo=self.demo, phone=phone, admin=phone in self.admins,
                    venue={key: venue[key] for key in branch_fields} if venue else None,
                    boxes=[box_json(b, current) for b in public],
                    inventory=[box_json(b, current) for b in inventory],
                    orders=[order_json(o, phone) for o in buyer], branchOrders=[order_json(o, phone) for o in branch],
                    staff=[r['phone'] for r in staff])

    def submit_venue(self, db, phone, body):
        title = string(body, 'title', 65)
        company = string(body, 'company', 65)
        address = string(body, 'address', 120)
        district = integer(body, 'district', 0, 2)
        lat, lng = number(body, 'lat', 50.9, 51.4), number(body, 'lng', 71.1, 71.8)
        with write(db):
            existing = venue_for(db, phone)
            if existing and (existing['role'] != 'owner' or existing['status'] != 'rejected'):
                raise ApiError(409, 'venue_exists')
            if existing:
                venue_id = existing['id']
                db.execute("""UPDATE venues SET name=?,company=?,address=?,district=?,lat=?,lng=?,
                    status='review',review_note='' WHERE id=?""", (title,company,address,district,lat,lng,venue_id))
            else:
                venue_id = secrets.token_hex(8)
                db.execute('''INSERT INTO venues(id,owner,name,company,address,district,lat,lng,status)
                    VALUES(?,?,?,?,?,?,?,?,'review')''', (venue_id,phone,title,company,address,district,lat,lng))
            record(db, phone, 'venue.submit', venue_id)
        return {'id': venue_id}

    def insert_box(self, db, venue, box_id, body, demo_seed=False):
        category = string(body, 'category', 10)
        images = {'bakery': 'bread', 'hot': 'bowl', 'coffee': 'pastry'}
        if category not in images:
            raise ApiError(400, 'invalid_input')
        price, original = integer(body, 'price', 1, 9999999), integer(body, 'original', 2, 9999999)
        if price * 2 > original:
            raise ApiError(400, 'invalid_input')
        window, day = string(body, 'window', 11, 11), string(body, 'day', 10, 10)
        try:
            if not re.fullmatch(r'[0-9]{2}:[0-9]{2}–[0-9]{2}:[0-9]{2}', window):
                raise ValueError
            starts, ends = [int(datetime.fromisoformat(day+'T'+part).replace(tzinfo=ASTANA).timestamp())
                            for part in window.split('–')]
        except ValueError:
            raise ApiError(400, 'invalid_pickup') from None
        if ends - starts < 1800 or not demo_seed and (ends <= now() or starts > now()+14*86400):
            raise ApiError(400, 'invalid_pickup')
        image = body.get('image', images[category])
        if image not in images.values():
            raise ApiError(400, 'invalid_input')
        details = dict(shop=venue['name'], ru=string(body, 'ru', 120), kk=string(body, 'kk', 120),
                       category=category, price=price, original=original, window=window,
                       address=venue['address'], district=venue['district'], lat=venue['lat'],
                       lng=venue['lng'], image=image, rating='—', distance='',
                       description=string(body, 'description', 500), merchant=True)
        db.execute('INSERT INTO boxes(id,venue_id,details,stock,starts,ends) VALUES(?,?,?,?,?,?)',
                   (box_id, venue['id'], json.dumps(details, ensure_ascii=False),
                    integer(body, 'stock', 1, 99), starts, ends))
        return {'id': box_id}

    def reserve(self, db, phone, body):
        box_id, key = string(body, 'boxId', 80), string(body, 'requestId', 80)
        quantity = integer(body, 'quantity', 1, 99)
        if not KEY.fullmatch(key):
            raise ApiError(400, 'invalid_input')
        with write(db):
            old = db.execute('SELECT * FROM orders WHERE buyer=? AND request_id=?', (phone,key)).fetchone()
            if old:
                if old['box_id'] != box_id or old['quantity'] != quantity:
                    raise ApiError(409, 'request_conflict')
                return order_json(old, phone)
            current = now()
            expire_orders(db, current)
            box = db.execute('''SELECT b.* FROM boxes b JOIN venues v ON v.id=b.venue_id
                WHERE b.id=? AND v.status='approved' AND b.published=1 AND b.paused=0 AND b.ends>?''',
                (box_id,current)).fetchone()
            if not box or box['stock'] < quantity:
                raise ApiError(409, 'sold_out')
            taken = {r[0] for r in db.execute("SELECT code FROM orders WHERE venue_id=? AND ends>?",
                                              (box['venue_id'], current))}
            free = [str(n) for n in range(1000,10000) if str(n) not in taken]
            if not free:
                raise ApiError(409, 'sold_out')
            order_id = 'TD-' + secrets.token_hex(5).upper()
            db.execute('UPDATE boxes SET stock=stock-? WHERE id=?', (quantity,box_id))
            db.execute('''INSERT INTO orders(id,buyer,request_id,box_id,venue_id,snapshot,quantity,
                          code,qr,created,ends,status) VALUES(?,?,?,?,?,?,?,?,?,?,?,'reserved')''',
                       (order_id,phone,key,box_id,box['venue_id'],
                        json.dumps(box_json(box,current), ensure_ascii=False),
                        quantity,secrets.choice(free),secrets.token_hex(16),current,box['ends']))
            record(db, phone, 'order.reserve', order_id)
            return order_json(db.execute('SELECT * FROM orders WHERE id=?', (order_id,)).fetchone(), phone)

    def order_action(self, db, phone, order_id, action, body):
        with write(db):
            order = db.execute('SELECT * FROM orders WHERE id=?', (order_id,)).fetchone()
            venue = venue_for(db, phone)
            buyer = order and order['buyer'] == phone
            branch = order and venue and venue['id'] == order['venue_id'] and venue['status'] == 'approved'
            if not order or not (buyer or action == 'cancel' and (branch or phone in self.admins)):
                raise ApiError(404, 'not_found')
            if action == 'cancel':
                if order['status'] == 'cancelled':
                    return {'ok': True}
                if order['status'] != 'reserved' or order['ends'] <= now():
                    raise ApiError(409, 'order_closed')
                db.execute("UPDATE orders SET status='cancelled' WHERE id=?", (order_id,))
                db.execute('UPDATE boxes SET stock=stock+? WHERE id=? AND ends>?',
                           (order['quantity'],order['box_id'],now()))
                record(db, phone, 'order.cancel', order_id)
            elif action == 'issue':
                issue = string(body, 'issue', 500)
                if order['issue']:
                    if order['issue'] == issue:
                        return {'ok': True}
                    raise ApiError(409, 'state_changed')
                db.execute("UPDATE orders SET issue=?,resolution='' WHERE id=?", (issue, order_id))
                record(db, phone, 'order.issue', order_id)
            elif action == 'review':
                if order['status'] != 'collected':
                    raise ApiError(409, 'order_closed')
                rating = integer(body, 'rating', 0, 5)
                feedback = body.get('feedback', [])
                if not isinstance(feedback,list) or len(feedback)>4 or any(x not in ('0','1','2','3') for x in feedback):
                    raise ApiError(400, 'invalid_input')
                db.execute('UPDATE orders SET rating=?,feedback=? WHERE id=?',
                           (rating,json.dumps(feedback),order_id))
            return {'ok': True}

    def pickup(self, db, phone, body, collect):
        key = string(body, 'code', 32)
        if not PICKUP.fullmatch(key):
            raise ApiError(400, 'invalid_code')
        with write(db):
            venue = require_venue(db, phone)
            self.limit(db, 'pickup:' + phone, 80, 60)
        with write(db):
            venue = require_venue(db, phone)
            current = now()
            order = db.execute('''SELECT o.*,b.starts FROM orders o JOIN boxes b ON b.id=o.box_id
                WHERE o.venue_id=? AND o.status='reserved' AND o.ends>? AND (o.code=? OR o.qr=?)''',
                (venue['id'],current,key,key)).fetchone()
            if not order:
                raise ApiError(404, 'pickup_missing')
            if not self.demo and order['starts'] > current:
                raise ApiError(409, 'pickup_early')
            if collect:
                if body.get('orderId') != order['id']:
                    raise ApiError(409, 'order_closed')
                db.execute("UPDATE orders SET status='collected',collected=? WHERE id=?", (current,order['id']))
                record(db,phone,'order.collect',order['id'])
                order = db.execute('SELECT * FROM orders WHERE id=?', (order['id'],)).fetchone()
            return order_json(order, phone)

    def admin(self, db, phone):
        if phone not in self.admins:
            raise ApiError(403, 'forbidden')
        current = now()
        venues = [dict(r) for r in db.execute('''
            SELECT v.*,
              (SELECT COUNT(*) FROM boxes b WHERE b.venue_id=v.id AND b.ends>?
               AND b.published=1 AND b.paused=0) AS live_listings,
              (SELECT COALESCE(SUM(o.quantity),0) FROM orders o WHERE o.venue_id=v.id
               AND o.status='collected' AND o.collected>=?) AS week_collected
            FROM venues v ORDER BY status,id
        ''', (current, current-7*86400))]
        listings = [dict(box_json(r,current), paused=bool(r['paused'])) for r in
                    db.execute('SELECT * FROM boxes ORDER BY starts DESC LIMIT 100')]
        rows = db.execute("SELECT * FROM orders ORDER BY (issue!='' AND resolution='') DESC,created DESC LIMIT 100").fetchall()
        orders = [dict(order_json(r, ''), issue=r['issue'], resolution=r['resolution'])
                  for r in rows]
        metrics = dict(db.execute("""SELECT CASE WHEN status='reserved' AND ends<=? THEN 'expired' ELSE status END,
            COUNT(*) FROM orders GROUP BY 1""", (current,)).fetchall())
        audit = [dict(r, occurred=iso(r['occurred'])) for r in
                 db.execute('SELECT * FROM audit ORDER BY id DESC LIMIT 30')]
        return dict(venues=venues, listings=listings, orders=orders, metrics=metrics, audit=audit)

    def dispatch(self, db, method, route, body, token, ip):
        if route == '/api/health' and method == 'GET':
            return {'ok': True, 'demo': self.demo}
        if route == '/api/auth/request' and method == 'POST':
            return self.request_code(db, body, ip)
        if route == '/api/auth/verify' and method == 'POST':
            return self.verify_code(db, body, ip)
        phone = ''
        if token:
            session = db.execute('SELECT phone FROM sessions WHERE token_hash=? AND expires>?',
                                 (digest(token),now())).fetchone()
            if not session:
                raise ApiError(401,'session_expired')
            phone = session['phone']
        if route == '/api/state' and method == 'GET':
            db.execute('BEGIN')
            return self.state(db, phone)
        if not phone:
            raise ApiError(401, 'sign_in')
        if route == '/api/auth/logout' and method == 'POST':
            db.execute('DELETE FROM sessions WHERE token_hash=?', (digest(token),))
            return {'ok': True}
        if route == '/api/venue' and method == 'POST':
            return self.submit_venue(db, phone, body)
        if route == '/api/orders' and method == 'POST':
            return self.reserve(db, phone, body)
        if match := re.fullmatch(r'/api/orders/(TD-[A-F0-9]{10})/(cancel|issue|review)', route):
            if method == 'POST':
                return self.order_action(db, phone, *match.groups(), body)
        if route in ('/api/pickup/check','/api/pickup/collect') and method == 'POST':
            return self.pickup(db, phone, body, route.endswith('collect'))
        if route == '/api/admin' and method == 'GET':
            db.execute('BEGIN')
            return self.admin(db, phone)
        if method == 'POST':
            return self.manage(db, phone, route, body)
        raise ApiError(404, 'not_found')

    def manage(self, db, phone, route, body):
        with write(db):
            if route == '/api/boxes':
                venue = require_venue(db, phone, owner=True)
                box_id = string(body,'id',80)
                if not KEY.fullmatch(box_id):
                    raise ApiError(400,'invalid_input')
                old = db.execute('SELECT venue_id FROM boxes WHERE id=?', (box_id,)).fetchone()
                if old:
                    if old['venue_id'] != venue['id']:
                        raise ApiError(404,'not_found')
                    return {'id': box_id}
                result = self.insert_box(db, venue, box_id, body)
                record(db,phone,'box.publish',box_id)
                return result
            if match := re.fullmatch(r'/api/boxes/([A-Za-z0-9_-]{1,80})/(stock|visibility)',route):
                venue = require_venue(db,phone,owner=True)
                box_id, field = match.groups()
                row = db.execute('SELECT * FROM boxes WHERE id=? AND venue_id=? AND ends>?',
                                 (box_id,venue['id'],now())).fetchone()
                if not row:
                    raise ApiError(404,'not_found')
                if field == 'stock':
                    old = integer(body,'expected',0,9999)
                    stock = integer(body,'stock',0,99)
                    if old != row['stock']:
                        raise ApiError(409,'stock_changed')
                    db.execute('UPDATE boxes SET stock=? WHERE id=?',(stock,box_id))
                else:
                    flag = body.get('published')
                    if type(flag) is not bool:
                        raise ApiError(400,'invalid_input')
                    if flag and row['paused']:
                        raise ApiError(409,'listing_paused')
                    db.execute('UPDATE boxes SET published=? WHERE id=?',(flag,box_id))
                record(db,phone,'box.'+field,box_id)
                return {'ok': True}
            if route in ('/api/staff/add','/api/staff/remove'):
                venue = require_venue(db,phone,owner=True)
                member = phone_value(body.get('phone'))
                if route.endswith('/add'):
                    existing = venue_for(db, member)
                    if member in self.admins or existing and (existing['id'] != venue['id'] or existing['role'] == 'owner'):
                        raise ApiError(409,'staff_conflict')
                    db.execute('INSERT OR IGNORE INTO staff VALUES(?,?)',(member,venue['id']))
                else:
                    db.execute('DELETE FROM staff WHERE phone=? AND venue_id=?',(member,venue['id']))
                record(db,phone,'staff.'+route.rsplit('/',1)[1],venue['id'],member)
                return {'ok': True}
            if route.startswith('/api/admin/'):
                if phone not in self.admins:
                    raise ApiError(403,'forbidden')
                return self.admin_action(db,phone,route,body)
        raise ApiError(404,'not_found')

    def admin_action(self, db, phone, route, body):
        if match := re.fullmatch(r'/api/admin/venues/([A-Za-z0-9_-]{1,80})',route):
            target = match[1]
            decision = body.get('status')
            if decision not in ('approved','rejected'):
                raise ApiError(400,'invalid_input')
            note = string(body,'note',250,0 if decision=='approved' else 1)
            changed = db.execute("UPDATE venues SET status=?,review_note=? WHERE id=? AND status='review'",
                                 (decision,note,target)).rowcount
            action = 'venue.'+decision
        elif match := re.fullmatch(r'/api/admin/listings/([A-Za-z0-9_-]{1,80})',route):
            target = match[1]
            paused = body.get('paused')
            if type(paused) is not bool:
                raise ApiError(400,'invalid_input')
            note = string(body,'note',250,0)
            changed = db.execute('UPDATE boxes SET paused=? WHERE id=?',(paused,target)).rowcount
            action = 'box.pause' if paused else 'box.resume'
        elif match := re.fullmatch(r'/api/admin/issues/(TD-[A-F0-9]{10})',route):
            target = match[1]
            note = string(body,'note',500)
            changed = db.execute("UPDATE orders SET resolution=? WHERE id=? AND issue!='' AND resolution=''",
                                 (note,target)).rowcount
            action = 'issue.resolve'
        else:
            raise ApiError(404,'not_found')
        if not changed:
            raise ApiError(409,'state_changed')
        record(db,phone,action,target,note)
        return {'ok': True}


def handler_for(pilot):
    class Handler(SimpleHTTPRequestHandler):
        server_version = 'toidym'

        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=str(pilot.web_root), **kwargs)

        def log_message(self, *args):
            # Avoid logging identifiers and user-supplied request paths.
            pass

        def list_directory(self, path):
            self.send_error(404)
            return None

        def end_headers(self):
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.send_header('Referrer-Policy', 'strict-origin-when-cross-origin')
            self.send_header('X-Frame-Options', 'DENY')
            self.send_header('Cache-Control', 'no-store' if self.path.startswith('/api/') else 'no-cache')
            super().end_headers()

        def do_GET(self):
            if urlsplit(self.path).path.startswith('/api/'):
                self.api('GET')
            else:
                super().do_GET()

        def do_POST(self):
            self.api('POST')

        def api(self, method):
            status = 200
            try:
                body = {}
                if method == 'POST':
                    size = int(self.headers.get('Content-Length', '0'))
                    if not 0 < size <= 16384 or self.headers.get_content_type() != 'application/json':
                        raise ApiError(400, 'invalid_input')
                    body = json.loads(self.rfile.read(size))
                    if not isinstance(body, dict):
                        raise ApiError(400, 'invalid_input')
                authorization = self.headers.get('Authorization', '')
                token = authorization[7:] if authorization.startswith('Bearer ') else ''
                with closing(pilot.connect()) as db:
                    data = pilot.dispatch(db, method, urlsplit(self.path).path, body, token, self.client_address[0])
            except ApiError as error:
                status, data = error.status, {'error': error.code}
            except (ValueError, UnicodeError):
                status, data = 400, {'error': 'invalid_input'}
            except Exception:
                logging.exception('API failure')
                status, data = 500, {'error': 'server_error'}
            payload = json.dumps(data, ensure_ascii=False).encode()
            self.send_response(status)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.send_header('Content-Length', str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
    return Handler


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--demo', action='store_true', help='Fake accounts, loopback only')
    parser.add_argument('--host', default='127.0.0.1')
    parser.add_argument('--port', type=int, default=8766)
    parser.add_argument('--db', type=Path)
    parser.add_argument('--web-root', type=Path, default=ROOT.parent / 'build' / 'web')
    args = parser.parse_args()
    if args.demo and args.host != '127.0.0.1':
        parser.error('--demo is available only on 127.0.0.1')
    admins = set(filter(None, (x.strip() for x in os.environ.get('TOIDYM_ADMINS', '').split(','))))
    if not args.demo and (not admins or any(not PHONE.fullmatch(x) for x in admins)):
        parser.error('Set TOIDYM_ADMINS to comma-separated +7 phone numbers')
    db_path = args.db or ROOT / 'data' / ('demo.sqlite3' if args.demo else 'pilot.sqlite3')
    try:
        pilot = Pilot(db_path, args.demo, admins, args.web_root.resolve())
    except ValueError as error:
        parser.error(str(error))
    with ThreadingHTTPServer((args.host, args.port), handler_for(pilot)) as server:
        print(f'Toidym {"demo" if args.demo else "pilot"}: http://{args.host}:{args.port}', flush=True)
        server.serve_forever()


if __name__ == '__main__':
    main()

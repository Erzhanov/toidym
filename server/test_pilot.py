import json
import tempfile
import threading
import unittest
from contextlib import closing
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta
from http.server import ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from server.app import ASTANA, DEMO_ADMIN, DEMO_CASHIER, DEMO_CODE, Pilot, handler_for


class PilotFlowTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.pilot = Pilot(self.root / 'test.sqlite3', True, set(), self.root)
        self.server = ThreadingHTTPServer(('127.0.0.1', 0), handler_for(self.pilot))
        self.addCleanup(self.server.server_close)
        self.addCleanup(self.server.shutdown)
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.url = 'http://127.0.0.1:' + str(self.server.server_port) + '/api/'

    def call(self, path, body=None, token='', status=200):
        headers = {'Content-Type': 'application/json'}
        if token:
            headers['Authorization'] = 'Bearer ' + token
        request = Request(self.url + path, None if body is None else json.dumps(body).encode(), headers)
        try:
            response = urlopen(request, timeout=8)
        except HTTPError as error:
            response = error
        with response:
            self.assertEqual(response.code, status)
            return json.load(response)

    def login(self, phone):
        self.call('auth/request', {'phone': phone})
        return self.call('auth/verify', {'phone': phone, 'code': DEMO_CODE})['token']

    def test_review_inventory_authorization_and_pickup(self):
        admin = self.login(DEMO_ADMIN)
        owner = self.login('+77000000005')
        cashier_phone = '+77000000006'
        buyer_a = self.login('+77000000007')
        buyer_b = self.login('+77000000008')
        wrong_branch = self.login(DEMO_CASHIER)

        self.call('admin', token=buyer_a, status=403)
        self.call('auth/verify', {'phone': DEMO_ADMIN, 'code': DEMO_CODE}, status=401)
        self.call('auth/request', {'phone': '+77777777777'}, status=400)

        venue = self.call('venue', {
            'title': 'Pilot bakery', 'company': 'Pilot company', 'address': 'Syganak, 16',
            'district': 0, 'lat': 51.12, 'lng': 71.42,
        }, owner)['id']
        tomorrow = (datetime.now(ASTANA) + timedelta(days=1)).date().isoformat()
        listing = {
            'id': 'pilot-test-bread', 'kk': 'Нан боксы', 'ru': 'Хлебный бокс',
            'category': 'bakery', 'price': 1000, 'original': 2400, 'stock': 1,
            'day': tomorrow, 'window': '17:00–18:00', 'description': 'Wheat',
        }
        self.call('boxes', listing, owner, 403)
        self.call('admin/venues/' + venue, {'status': 'approved', 'note': ''}, buyer_a, 403)
        self.call('admin/venues/' + venue, {'status': 'approved', 'note': ''}, admin)
        self.call('staff/add', {'phone': cashier_phone}, owner)
        cashier = self.login(cashier_phone)
        self.call('boxes', listing, cashier, 403)
        self.call('boxes', listing, owner)

        def reserve(token, suffix):
            body = {'boxId': listing['id'], 'quantity': 1, 'requestId': 'reserve-test-' + suffix}
            request = Request(self.url + 'orders', json.dumps(body).encode(), {
                'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json',
            })
            try:
                with urlopen(request, timeout=8) as result:
                    return token, body, result.code, json.load(result)
            except HTTPError as error:
                with error:
                    return token, body, error.code, json.load(error)

        with ThreadPoolExecutor(2) as pool:
            first = pool.submit(reserve, buyer_a, 'A')
            second = pool.submit(reserve, buyer_b, 'B')
            results = sorted([first.result(), second.result()], key=lambda row: row[2])
        winner, body, status, order = results[0]
        self.assertEqual([status, results[1][2]], [200, 409])
        self.assertEqual(self.call('orders', body, winner)['id'], order['id'])
        current = next(box for box in self.call('state')['boxes'] if box['id'] == listing['id'])
        self.assertEqual(current['stock'], 0)
        self.assertEqual(self.call('boxes/' + listing['id'] + '/stock', {'stock': 2, 'expected': 1},
                                   owner, 409)['error'], 'stock_changed')

        branch_order = self.call('state', token=cashier)['branchOrders'][0]
        self.assertEqual((branch_order['code'], branch_order['qr'], branch_order['owner']), ('', '', ''))
        self.call('pickup/check', {'code': order['code']}, wrong_branch, 404)
        self.call('pickup/check', {'code': order['qr']}, winner, 403)
        self.assertEqual(self.call('pickup/check', {'code': order['qr']}, cashier)['id'], order['id'])
        collect = {'code': order['qr'], 'orderId': order['id']}
        self.call('pickup/collect', collect, cashier)
        self.call('pickup/collect', collect, cashier, 404)
        self.assertEqual(self.call('state', token=winner)['orders'][0]['status'], 'collected')

        issue = 'orders/' + order['id'] + '/issue'
        self.call(issue, {'issue': 'Packaging'}, winner)
        self.call('admin/issues/' + order['id'], {'note': 'Resolved'}, admin)
        self.assertEqual(self.call('state', token=winner)['orders'][0]['resolution'], 'Resolved')
        self.assertIn('order.collect', [row['action'] for row in self.call('admin', token=admin)['audit']])

        self.call('boxes/' + listing['id'] + '/stock', {'stock': 1, 'expected': 0}, owner)
        other = self.call('orders', {**body, 'requestId': 'reserve-test-cancel'}, buyer_b)
        self.assertNotEqual(other['code'], order['code'])
        self.call('orders/' + other['id'] + '/cancel', {}, buyer_b)
        self.call('orders/' + other['id'] + '/cancel', {}, buyer_b)
        self.assertEqual(self.call('state', token=owner)['inventory'][0]['stock'], 1)

        reopened = Pilot(self.pilot.path, True, set(), self.root)
        with closing(reopened.connect()) as db:
            self.assertEqual(db.execute('SELECT status FROM orders WHERE id=?', (order['id'],)).fetchone()[0], 'collected')


if __name__ == '__main__':
    unittest.main()

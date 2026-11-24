/**
 * End-to-end test of the main shopping flow against a real Postgres.
 *
 *   TEST_DATABASE_URL=postgresql://postgres:pass@localhost:5432/kachipapa_test npm run test:e2e
 *
 * WARNING: the test database is wiped before the run.
 */
import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { DataSource } from 'typeorm';
import request from 'supertest';
import { App } from 'supertest/types';

const dbUrl = process.env.TEST_DATABASE_URL;
const describeIfDb = dbUrl ? describe : describe.skip;

describeIfDb('Kachipapa Store API (e2e)', () => {
  let app: INestApplication<App>;
  let http: ReturnType<typeof request>;
  let adminToken: string;
  let customerToken: string;
  let shirtId: number;
  let orderId: number;

  beforeAll(async () => {
    process.env.DATABASE_URL = dbUrl;
    process.env.JWT_SECRET = 'e2e-test-secret-e2e-test-secret-1234';
    process.env.ADMIN_SETUP_KEY = 'e2e-setup-key';

    // Start from an empty schema, then let migrations build it.
    const { buildDataSourceOptions } =
      await import('../src/config/database.config');
    const ds = new DataSource({
      ...buildDataSourceOptions(),
      migrationsRun: false,
    });
    await ds.initialize();
    await ds.query('DROP SCHEMA public CASCADE; CREATE SCHEMA public;');
    await ds.destroy();

    const { AppModule } = await import('../src/app.module');
    const { configureApp } = await import('../src/app.setup');
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
    http = request(app.getHttpServer());
  });

  afterAll(async () => {
    await app?.close();
  });

  it('reports healthy', () =>
    http.get('/api/health').expect(200, { status: 'ok' }));

  describe('admin setup', () => {
    it('refuses admin registration without the setup key', () =>
      http
        .post('/api/admin/auth/register')
        .send({ email: 'boss@kachipapa.mw', password: 'supersecret1' })
        .expect(403));

    it('registers the first admin with the setup key', () =>
      http
        .post('/api/admin/auth/register')
        .set('X-Setup-Key', 'e2e-setup-key')
        .send({ email: 'boss@kachipapa.mw', password: 'supersecret1' })
        .expect(201));

    it('refuses a second admin', () =>
      http
        .post('/api/admin/auth/register')
        .set('X-Setup-Key', 'e2e-setup-key')
        .send({ email: 'other@kachipapa.mw', password: 'supersecret1' })
        .expect(409));

    it('logs the admin in', async () => {
      const res = await http
        .post('/api/admin/auth/login')
        .send({ email: 'boss@kachipapa.mw', password: 'supersecret1' })
        .expect(201);
      adminToken = res.body.access_token;
      expect(adminToken).toBeTruthy();
    });
  });

  describe('products', () => {
    it('blocks guests from creating products', () =>
      http
        .post('/api/products')
        .send({ name: 'x', category: 'mens_clothing', price: 1, stock: 1 })
        .expect(401));

    it('rejects an unknown category', () =>
      http
        .post('/api/products')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ name: 'Shirt', category: 'Mens', price: 4500, stock: 3 })
        .expect(400));

    it('creates a product (multipart form, like the admin app)', async () => {
      const res = await http
        .post('/api/products')
        .set('Authorization', `Bearer ${adminToken}`)
        .field('name', 'Classic Oxford Shirt')
        .field('category', 'mens_clothing')
        .field('price', '4500')
        .field('stock', '3')
        .field('discount', '35')
        .field('sizes', 'S,M,L')
        .expect(201);
      shirtId = res.body.id;
      expect(res.body.price).toBe(4500);
      expect(res.body.sizes).toEqual(['S', 'M', 'L']);
    });

    it('lists products publicly with numeric prices', async () => {
      const res = await http.get('/api/products').expect(200);
      expect(res.body).toHaveLength(1);
      expect(typeof res.body[0].price).toBe('number');
    });

    it('filters by category and searches', async () => {
      expect(
        (await http.get('/api/products/category/mens_clothing').expect(200))
          .body,
      ).toHaveLength(1);
      expect(
        (await http.get('/api/products/search?q=oxford').expect(200)).body,
      ).toHaveLength(1);
    });
  });

  describe('customers', () => {
    it('registers a customer and returns a token', async () => {
      const res = await http
        .post('/api/customer/auth/register')
        .send({
          name: 'Chikondi Banda',
          email: 'Chikondi@example.mw',
          password: 'password123',
          phone: '0991234567',
        })
        .expect(201);
      customerToken = res.body.access_token;
      expect(res.body.customer.email).toBe('chikondi@example.mw');
      expect(res.body.customer.password).toBeUndefined();
    });

    it('rejects a duplicate email', () =>
      http
        .post('/api/customer/auth/register')
        .send({
          name: 'X',
          email: 'chikondi@example.mw',
          password: 'password123',
        })
        .expect(409));

    it('logs in and returns the profile without the password', async () => {
      await http
        .post('/api/customer/auth/login')
        .send({ email: 'chikondi@example.mw', password: 'password123' })
        .expect(201);
      const res = await http
        .get('/api/customer/profile')
        .set('Authorization', `Bearer ${customerToken}`)
        .expect(200);
      expect(res.body.name).toBe('Chikondi Banda');
      expect(res.body.password).toBeUndefined();
    });

    it('does not let a customer token act as admin', () =>
      http
        .get('/api/admin/orders')
        .set('Authorization', `Bearer ${customerToken}`)
        .expect(403));
  });

  describe('wishlist', () => {
    it('adds, lists and removes', async () => {
      const auth = { Authorization: `Bearer ${customerToken}` };
      await http.post(`/api/wishlist/${shirtId}`).set(auth).expect(201);
      await http.post(`/api/wishlist/${shirtId}`).set(auth).expect(201); // idempotent
      expect(
        (await http.get('/api/wishlist').set(auth).expect(200)).body,
      ).toHaveLength(1);
      await http.delete(`/api/wishlist/${shirtId}`).set(auth).expect(200);
      expect(
        (await http.get('/api/wishlist').set(auth).expect(200)).body,
      ).toHaveLength(0);
    });
  });

  describe('checkout', () => {
    const order = (quantity: number) => ({
      customerName: 'Chikondi Banda',
      customerEmail: 'chikondi@example.mw',
      customerPhone: '0991234567',
      deliveryAddress: 'Area 47, Sector 3',
      deliveryCity: 'Lilongwe',
      paymentMethod: 'airtel_money',
      items: [{ productId: shirtId, quantity, size: 'M' }],
    });

    it('ignores client-sent prices and computes the total on the server', async () => {
      const res = await http
        .post('/api/orders')
        .set('Authorization', `Bearer ${customerToken}`)
        .send(order(2))
        .expect(201);
      orderId = res.body.id;
      expect(res.body.subtotal).toBe(9000);
      expect(res.body.totalAmount).toBe(9000); // above the free-delivery threshold
      expect(res.body.customerId).toBeTruthy();
    });

    it('rejects a request that tries to set its own price', () =>
      http
        .post('/api/orders')
        .send({
          ...order(1),
          totalAmount: 1,
          items: [{ productId: shirtId, quantity: 1, price: 1 }],
        })
        .expect(400));

    it('reduced stock and refuses to oversell', async () => {
      expect(
        (await http.get(`/api/products/${shirtId}`).expect(200)).body.stock,
      ).toBe(1);
      await http.post('/api/orders').send(order(5)).expect(400);
    });

    it('allows guest checkout', async () => {
      const res = await http.post('/api/orders').send(order(1)).expect(201);
      expect(res.body.customerId).toBeNull();
    });

    it("shows the customer's own orders", async () => {
      const res = await http
        .get('/api/orders/mine')
        .set('Authorization', `Bearer ${customerToken}`)
        .expect(200);
      expect(res.body).toHaveLength(1);
    });

    it('tracks an order only with the matching phone number', async () => {
      await http
        .get(`/api/orders/track/${orderId}?phone=0888000000`)
        .expect(404);
      const res = await http
        .get(`/api/orders/track/${orderId}?phone=%2B265991234567`)
        .expect(200);
      expect(res.body.status).toBe('pending');
      expect(res.body.customerEmail).toBeUndefined();
    });
  });

  describe('admin order handling', () => {
    const auth = () => ({ Authorization: `Bearer ${adminToken}` });

    it('notifies the admin about new orders and low stock', async () => {
      const res = await http
        .get('/api/admin/notifications')
        .set(auth())
        .expect(200);
      const types = res.body.map((n: { type: string }) => n.type);
      expect(types).toContain('order');
      expect(types).toContain('stock');
    });

    it('records payment and updates status', async () => {
      await http
        .patch(`/api/admin/orders/${orderId}/payment`)
        .set(auth())
        .send({ paymentStatus: 'paid', transactionId: 'AM12345' })
        .expect(200);
      await http
        .patch(`/api/admin/orders/${orderId}/status`)
        .set(auth())
        .send({ status: 'processing' })
        .expect(200);
      const stats = (
        await http.get('/api/admin/orders/stats').set(auth()).expect(200)
      ).body;
      expect(stats.totalRevenue).toBe(9000);
      expect(stats.processing).toBe(1);
    });

    it('puts stock back when an order is cancelled', async () => {
      await http
        .patch(`/api/admin/orders/${orderId}/status`)
        .set(auth())
        .send({ status: 'cancelled' })
        .expect(200);
      expect(
        (await http.get(`/api/products/${shirtId}`).expect(200)).body.stock,
      ).toBe(2);
      const history = (
        await http
          .get(`/api/inventory/history/${shirtId}`)
          .set(auth())
          .expect(200)
      ).body;
      expect(history.transactions.map((t: { type: string }) => t.type)).toEqual(
        ['RETURN', 'SALE', 'SALE'],
      );
    });

    it('serves inventory and analytics', async () => {
      await http
        .post('/api/inventory/add-stock')
        .set(auth())
        .send({ productId: shirtId, quantity: 10 })
        .expect(201);
      expect(
        (await http.get(`/api/products/${shirtId}`).expect(200)).body.stock,
      ).toBe(12);
      await http.get('/api/admin/analytics/summary').set(auth()).expect(200);
      const top = (
        await http
          .get('/api/admin/analytics/top-products')
          .set(auth())
          .expect(200)
      ).body;
      expect(top[0].totalSold).toBe(1); // the cancelled order doesn't count
    });
  });

  describe('reviews and settings', () => {
    it('lets a customer review once and shows it publicly', async () => {
      const auth = { Authorization: `Bearer ${customerToken}` };
      await http
        .post('/api/reviews')
        .set(auth)
        .send({ productId: shirtId, rating: 5, comment: 'Great fit' })
        .expect(201);
      await http
        .post('/api/reviews')
        .set(auth)
        .send({ productId: shirtId, rating: 4 })
        .expect(409);
      const summary = (
        await http.get(`/api/reviews/product/${shirtId}/summary`).expect(200)
      ).body;
      expect(summary).toEqual({ reviewCount: 1, rating: 5 });
    });

    it('applies the delivery fee below the free-delivery threshold', async () => {
      await http
        .patch('/api/admin/settings')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ deliveryFee: 1500, freeDeliveryThreshold: 50000 })
        .expect(200);
      expect(
        (await http.get('/api/settings').expect(200)).body.deliveryFee,
      ).toBe(1500);
      const res = await http
        .post('/api/orders')
        .send({
          customerName: 'Guest',
          customerEmail: 'guest@example.mw',
          customerPhone: '+265881234567',
          deliveryAddress: 'Chichiri',
          deliveryCity: 'Blantyre',
          paymentMethod: 'cash',
          items: [{ productId: shirtId, quantity: 1 }],
        })
        .expect(201);
      expect(res.body.totalAmount).toBe(6000);
    });
  });
});

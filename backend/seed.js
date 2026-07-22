/**
 * SEED SCRIPT — Handover Cleanup
 * 
 * Drops ALL collections, creates single admin user + default settings.
 * Run: node seed.js
 */

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const config = require('./src/config/index');

const MONGO_URI = config.mongodb.uri;

// ── Single admin user ──
const ADMIN = {
  email: 'admin@re.com',
  password: 'Admin@re2026',
  fullName: 'RATHOD ENTERPRISES',
  role: 'admin',
  isActive: true,
};

// ── Default business settings ──
const BUSINESS = {
  businessName: 'RATHOD ENTERPRISES',
  tagline: 'Vegetable, Fruits Supplier & Commission Agent',
  address: 'Shop No.95 Kanji House, Mahatma Phule Market, Cotton Market, Nagpur – 440018',
  phone: '8087344819',
  gstNumber: '',
  invoicePrefix: 'RE',
  footerNote: 'Thank you for your business!',
};

// ── All collection names to drop ──
const COLLECTIONS_TO_DROP = [
  'users',
  'products',
  'customers',
  'bills',
  'billitems',
  'bill_items',
  'payments',
  'ledgerentries',
  'ledger_entries',
  'dailyrates',
  'daily_rates',
  'businesssettings',
  'business_settings',
  'counters',
  'auditlogs',
  'audit_logs',
];

async function run() {
  console.log('Connecting to MongoDB...');
  await mongoose.connect(MONGO_URI);
  const db = mongoose.connection.db;
  console.log(`Connected to: ${db.databaseName}`);

  // ── Step 1: Drop all collections ──
  console.log('\n── Dropping all collections ──');
  const collections = await db.listCollections().toArray();
  for (const col of collections) {
    try {
      await db.dropCollection(col.name);
      console.log(`  ✓ Dropped: ${col.name}`);
    } catch (e) {
      console.log(`  ✗ Skipped: ${col.name} (${e.message})`);
    }
  }

  // ── Step 2: Create admin user ──
  console.log('\n── Creating admin user ──');
  const hashedPassword = await bcrypt.hash(ADMIN.password, 12);
  const usersCol = db.collection('users');
  await usersCol.insertOne({
    email: ADMIN.email.toLowerCase(),
    password: hashedPassword,
    fullName: ADMIN.fullName,
    role: ADMIN.role,
    isActive: ADMIN.isActive,
    createdAt: new Date(),
    updatedAt: new Date(),
  });
  console.log(`  ✓ Created: ${ADMIN.email} (${ADMIN.role})`);

  // ── Step 3: Create business settings ──
  console.log('\n── Creating business settings ──');
  const settingsCol = db.collection('businesssettings');
  await settingsCol.insertOne({
    ...BUSINESS,
    createdAt: new Date(),
    updatedAt: new Date(),
  });
  console.log(`  ✓ Created: ${BUSINESS.businessName}`);

  // ── Done ──
  console.log('\n── Summary ──');
  console.log(`  Email:    ${ADMIN.email}`);
  console.log(`  Password: ${ADMIN.password}`);
  console.log(`  Role:     ${ADMIN.role}`);
  console.log(`  Business: ${BUSINESS.businessName}`);
  console.log('\nSeed complete. Disconnecting...');
  
  await mongoose.disconnect();
  console.log('Done.');
}

run().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});

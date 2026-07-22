/**
 * SEED PRODUCTS — Inserts all 40 mandi products
 * Safe to run multiple times (uses upsert by name).
 * Run: node seed_products.js
 */

const mongoose = require('mongoose');
const config = require('./src/config/index');

const MONGO_URI = config.mongodb.uri;

const PRODUCTS = [
  { name: 'Potato',              nameHindi: 'आलू',           unit: 'kg' },
  { name: 'Onion',               nameHindi: 'प्याज',          unit: 'kg' },
  { name: 'New Potato',          nameHindi: 'कापशी आलू',     unit: 'kg' },
  { name: 'Cauliflower',         nameHindi: 'फूलगोभी',       unit: 'kg' },
  { name: 'Cabbage',             nameHindi: 'पत्तागोभी',     unit: 'kg' },
  { name: 'Capsicum',            nameHindi: 'शिमला मिर्च',   unit: 'kg' },
  { name: 'Beetroot',            nameHindi: 'बीट',           unit: 'kg' },
  { name: 'Carrot',              nameHindi: 'गाजर',          unit: 'kg' },
  { name: 'Cucumber',            nameHindi: 'ककड़ी',          unit: 'kg' },
  { name: 'Coriander Leaves',    nameHindi: 'धनिया',          unit: 'kg' },
  { name: 'Green Chilli',        nameHindi: 'हरी मिर्च',     unit: 'kg' },
  { name: 'Ginger',              nameHindi: 'अदरक',          unit: 'kg' },
  { name: 'Garlic',              nameHindi: 'लहसुन',         unit: 'kg' },
  { name: 'Cherry Tomato',       nameHindi: 'चेरी टमाटर',    unit: 'kg' },
  { name: 'Bhaji Chilli',        nameHindi: 'भाजीया मिर्च',  unit: 'kg' },
  { name: 'Spinach (Palak)',     nameHindi: 'पालक',          unit: 'kg' },
  { name: 'Lemon',               nameHindi: 'नींबू',          unit: 'pcs' },
  { name: 'Fenugreek Leaves',    nameHindi: 'मेथी',           unit: 'kg' },
  { name: 'Spring Onion',        nameHindi: 'हरा प्याज',     unit: 'kg' },
  { name: 'Mint Leaves',         nameHindi: 'पुदीना',        unit: 'bunch' },
  { name: 'Curry Leaves',        nameHindi: 'कड़ी पत्ता',    unit: 'kg' },
  { name: 'Bottle Gourd',        nameHindi: 'लौकी',          unit: 'kg' },
  { name: 'Brinjal',             nameHindi: 'बैंगन',         unit: 'kg' },
  { name: 'Round Brinjal',       nameHindi: 'भरता बैंगन',   unit: 'kg' },
  { name: 'Bitter Gourd',        nameHindi: 'करेला',         unit: 'kg' },
  { name: 'Okra',                nameHindi: 'भिंडी',         unit: 'kg' },
  { name: 'Pumpkin',             nameHindi: 'कुम्हड़ा',      unit: 'kg' },
  { name: 'Mustard Greens',      nameHindi: 'सरसों साग',     unit: 'kg' },
  { name: 'Mixed Vegetables',    nameHindi: 'मिक्स फलसब्जी', unit: 'kg' },
  { name: 'Pineapple',           nameHindi: 'पायनापल',       unit: 'pcs' },
  { name: 'Apple',               nameHindi: 'सेब',           unit: 'kg' },
  { name: 'Chikoo (Sapota)',     nameHindi: 'चीकू',          unit: 'kg' },
  { name: 'Pomegranate',         nameHindi: 'अनार',          unit: 'kg' },
  { name: 'Banana',              nameHindi: 'केला',          unit: 'kg' },
  { name: 'Papaya',              nameHindi: 'पपीता',         unit: 'kg' },
  { name: 'Mosambi (Sweet Lime)', nameHindi: 'मोसंबी',       unit: 'kg' },
  { name: 'Grapes',              nameHindi: 'अंगूर',         unit: 'kg' },
  { name: 'Watermelon',          nameHindi: 'तरबूज',         unit: 'kg' },
  { name: 'Muskmelon',           nameHindi: 'खरबूज',         unit: 'kg' },
  { name: 'Orange',              nameHindi: 'संतरा',         unit: 'kg' },
];

async function run() {
  console.log('Connecting to MongoDB...');
  await mongoose.connect(MONGO_URI);
  const db = mongoose.connection.db;
  console.log(`Connected to: ${db.databaseName}`);

  const productsCol = db.collection('products');
  let inserted = 0;
  let updated = 0;
  let skipped = 0;

  console.log(`\nSeeding ${PRODUCTS.length} products...\n`);

  for (const p of PRODUCTS) {
    const now = new Date();
    const result = await productsCol.updateOne(
      { name: p.name, isDeleted: false },
      {
        $set: {
          nameHindi: p.nameHindi,
          unit: p.unit,
          isActive: true,
          isDeleted: false,
          updatedAt: now,
        },
        $setOnInsert: {
          name: p.name,
          createdAt: now,
        },
      },
      { upsert: true }
    );

    if (result.upsertedCount > 0) {
      inserted++;
      console.log(`  + ${p.name} (${p.nameHindi}) [${p.unit}]`);
    } else if (result.modifiedCount > 0) {
      updated++;
      console.log(`  ~ ${p.name} (${p.nameHindi}) [${p.unit}] — updated`);
    } else {
      skipped++;
    }
  }

  console.log(`\n── Summary ──`);
  console.log(`  Inserted: ${inserted}`);
  console.log(`  Updated:  ${updated}`);
  console.log(`  Skipped:  ${skipped} (already up-to-date)`);
  console.log(`  Total:    ${PRODUCTS.length}`);

  console.log('\nSeeding complete. Disconnecting...');
  await mongoose.disconnect();
  console.log('Done.');
}

run().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});

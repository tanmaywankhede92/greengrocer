const Product = require('../models/Product');

const findProducts = async ({ activeOnly = false, search = '' }) => {
  const filter = { isDeleted: false };
  if (activeOnly) filter.isActive = true;
  if (search) {
    filter.$or = [
      { name: { $regex: search, $options: 'i' } },
      { nameHindi: { $regex: search, $options: 'i' } },
    ];
  }
  return Product.find(filter).sort({ name: 1 }).lean();
};

const findById = async (id) => {
  return Product.findOne({ _id: id, isDeleted: false });
};

const createProduct = async (data) => {
  return Product.create(data);
};

const updateProduct = async (id, data) => {
  return Product.findByIdAndUpdate(id, data, { new: true, runValidators: true });
};

const toggleActive = async (id, isActive) => {
  return Product.findByIdAndUpdate(id, { isActive }, { new: true });
};

module.exports = {
  findProducts,
  findById,
  createProduct,
  updateProduct,
  toggleActive,
};

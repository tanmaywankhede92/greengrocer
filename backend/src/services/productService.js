const productRepository = require('../repositories/productRepository');

const listProducts = async (query) => {
  return productRepository.findProducts(query);
};

const createProduct = async (data) => {
  return productRepository.createProduct(data);
};

const updateProduct = async (id, data) => {
  const product = await productRepository.updateProduct(id, data);
  if (!product) {
    const error = new Error('Product not found');
    error.statusCode = 404;
    throw error;
  }
  return product;
};

const toggleProduct = async (id, isActive) => {
  const product = await productRepository.toggleActive(id, isActive);
  if (!product) {
    const error = new Error('Product not found');
    error.statusCode = 404;
    throw error;
  }
  return product;
};

const deleteProduct = async (id) => {
  const product = await productRepository.softDelete(id);
  if (!product) {
    const error = new Error('Product not found');
    error.statusCode = 404;
    throw error;
  }
  return product;
};

module.exports = { listProducts, createProduct, updateProduct, toggleProduct, deleteProduct };

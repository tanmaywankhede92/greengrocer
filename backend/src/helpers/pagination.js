const getPagination = (query) => {
  const page = Math.max(1, parseInt(query.page, 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit, 10) || 20));
  const skip = (page - 1) * limit;
  return { page, limit, skip };
};

const getSort = (query, defaultField = 'createdAt', defaultOrder = 'desc') => {
  const field = query.sort || defaultField;
  const order = query.order === 'asc' ? 1 : -1;
  return { [field]: order };
};

const buildMeta = (total, page, limit) => {
  return {
    page,
    limit,
    total,
    totalPages: Math.ceil(total / limit) || 1,
    hasNextPage: page * limit < total,
    hasPreviousPage: page > 1,
  };
};

module.exports = { getPagination, getSort, buildMeta };

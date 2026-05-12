const DEFAULT_LIMIT = 10;
const MAX_LIMIT = 100;

const parseNumber = (value) => {
  const parsed = Number.parseInt(value, 10);
  return Number.isNaN(parsed) ? null : parsed;
};

exports.getPaginationOptions = (query = {}) => {
  const parsedLimit = parseNumber(query.limit);
  const parsedPage = parseNumber(query.page);

  const limit =
    parsedLimit && parsedLimit > 0
      ? Math.min(parsedLimit, MAX_LIMIT)
      : DEFAULT_LIMIT;

  const page = parsedPage && parsedPage > 0 ? parsedPage : 1;
  const skip = (page - 1) * limit;

  return { skip, limit, page };
};

exports.buildPaginationMeta = ({ totalItems, skip, limit, page }) => {
  const totalPages = totalItems > 0 ? Math.ceil(totalItems / limit) : 0;

  return {
    totalItems,
    skip,
    limit,
    page,
    totalPages,
    hasNextPage: skip + limit < totalItems,
    hasPrevPage: skip > 0,
  };
};

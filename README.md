# Data documentation

No external dataset file is required. The fictional sample data is created by `../sql/01_setup_and_data.sql`.

## Tables
- `customers`: one row per fictional customer; includes region.
- `products`: one row per fictional product; includes category.
- `orders`: one row per order, with quantity, unit price, promised/delivered dates, and recorded shipping cost.

## Data caveats
- All names and records are fictional.
- One order is undelivered and has no reporting/as-of date, so it cannot be classified as overdue from this data alone.
- `shipping_cost` is not defined as a customer charge or fully allocated cost.
- `quantity * unit_price` is product revenue only; there are no costs/margins to calculate profit.

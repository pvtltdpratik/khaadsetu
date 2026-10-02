/// Every phrase the app shows that has a Marathi and Hindi translation (see strings_mr.dart, strings_hi.dart).
/// The phrase itself is the lookup key everywhere else in the app (`Tx('Save')`, `context.t('Save')`), so this
/// file is not read by the app at runtime — it exists so a person can see the whole list in one place, and so a
/// test can check that both translation files cover exactly this list, with nothing missing and nothing stale.
const enPhrases = <String>[
  'Language', 'Save', 'Cancel', 'Later', 'Try again', 'Send', 'Approve', 'Send back', 'Refuse', 'Clear', 'All', 'Everyone',
  // Update prompt
  'Restart required', 'Updating the app', 'Restart now', 'Open the setting',
  'The app needs to restart to finish the update. Android will ask you to tap Install; then open the app again.',
  'Allow this app to install updates on the page that opened, then come back here.',
  // Vehicles
  'My vehicles', 'Add a vehicle', 'Vehicle', 'Change details', 'Photos', 'Papers', 'Send to a village center',
  'Send for checking', 'Kind of vehicle', 'Registration number', 'No vehicle yet',
  // Board
  'Deliver & Earn', 'Delivery job', 'My requests', 'Take this delivery', 'Ask the village center', 'Filters',
  'Show jobs', 'Route', 'Carrying', 'Your vehicle', 'Distance', 'Sort by', 'Withdraw',
  // Farmer-made products
  'Farmer-made products', 'Farmer-made', 'Product', 'My home-made products', 'Add a product', 'My product',
  'Farmer-made orders', 'Order', 'Place order', 'Mark ready', 'Rate the seller', 'Cancel this order',
  'Handed over, paid', 'Ask a partner to deliver', 'Your pickup code', 'Your part', 'Your earnings', 'Reviews',
  'About', 'I sold', 'I bought', 'Sort', 'Nearest', 'Cheapest', 'Best rated', 'Newest',
  // Center and admin
  'To check', 'Vehicles', 'Long trips', 'Products', 'Earnings', 'My profile', 'Farmer', 'Money', 'Recent orders',
  'Monthly target', 'Last 7 days', 'Monthly statement', 'Payout account', 'Me as a farmer', 'Activity log',
  'My activity', 'Community AI', 'Scheme reach', 'Center activity', 'Refused only', 'Nothing recorded yet.',
  'Was this answer helpful?', 'Thank you for telling us.',
  // Bottom navigation
  'Home', 'Soil Scan', 'Marketplace', 'Community', 'Profile',
  // Home screen
  'Good morning', 'Good afternoon', 'Good evening', 'Scan your soil', 'Know what your soil needs', 'Ask the assistant',
  "Today's weather", 'Your farm', 'Recommended for you', 'See all', 'Notifications', 'Set your location',
  'Your current location',
  // Marketplace
  'Search products', 'Categories', 'Compare', 'Add to cart', 'View cart', 'In stock', 'Out of stock', 'Price',
  'Rating', 'Checkout', 'Total', 'Quantity', 'Description', 'Nutrient focus', 'Soil match', 'No products found',
  // Auth
  'Sign in', 'Sign up', 'Create your account', 'Join ShetSamrudhi in a minute', 'Full name', 'Email', 'Password',
  'Already have an account?', 'Create account', 'Sign out', 'Add a photo (optional)', 'Take a photo',
  'Choose from gallery', 'Remove photo',
  // Village picker / centers
  'Choose your village', 'Search your village or district', 'Near you', 'Done', 'Change',
  'Village centers near you', 'Choose a center',
  // Own products sell form
  'What is it made from?', 'About it (optional)', 'How much you have', 'Least one can buy', 'Village',
  'I promise it is organic: no chemical fertilizer or pesticide', 'Delete',
  // Orders / order detail
  'Order Details', 'App order', 'Walk-in sale', 'Items', 'Mark ready for pickup', 'Verify pickup OTP', 'Paid by',
  'Verify & complete',
  // Assistant
  'Farming assistant', 'New chat', 'Ask about crops, soil, schemes…',
  // Marketplace (filter sheet, promos, compare)
  'Any', 'Apply', 'Ask AI', 'Ask the farming assistant about your crop and soil', 'Clear search and filters',
  'Compare products', 'Compare selected products', 'Customer rating', 'Equipment',
  'Farmers\' unused fertilizer, inspected at your center, at a lower price', 'Fertilizer', 'Filter',
  'Find a village center', 'Matches my soil', 'Matches your soil', 'My Orders', 'My orders', 'Nearby Centers',
  'No products match', 'Not sure what to buy?', 'Only products for the nutrients your latest scan found low',
  'Organic', 'Pesticide', 'Pickup at your village center', 'Price up to', 'Price ↑', 'Price ↓',
  'Price: high to low', 'Price: low to high', 'Relevance', 'Scan Soil', 'Scan soil now',
  'Scan your soil first to use this', 'Scan your soil to get a health score and fertilizer guidance.',
  'Search fertilizers, seeds, neem, vermicompost…', 'See who has your product in stock and how far it is', 'Seed',
  'Send a Load', 'Stop comparing', 'Suggested for you', 'Surplus deals near you',
  'Try a different word or remove a filter.', 'View details', 'You can only compare 2 products at a time',
  // Home screen location and greeting
  'Finding your location…', 'I am a', 'Namaste', 'Today', 'Your location',
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  // Village picker
  'No village centers near', 'No village matches', 'Village centers near', 'yet.',
  // Assistant screen
  'The assistant is not available right now', 'You can still ask other farmers in the Community tab.',
  'नमस्कार! How can I help your farm today?',
  'Ask in Marathi, Hindi or English. I know your land, crops and soil scan from your profile.',
  'The assistant can make mistakes. For serious crop or animal problems, also ask your Taluka Agriculture Officer or call the Kisan Call Center on 1800-180-1551.',
  // Center card / nearby centers
  'Call', 'Choose this center', 'No village centers within', 'Open in Maps', 'Open', 'Closed', 'pickup waiting',
  'pickups waiting', 'Pick where you will collect your order.', 'Recommended', 'Recommended center', 'Run by',
  'Stock shown is for the item you are looking at.', 'This center cannot fill your whole order.', 'Within',
  'about', 'away', 'best match first',
];

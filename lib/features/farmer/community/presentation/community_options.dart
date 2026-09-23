/// No "distinct crop/district values" endpoint exists on the server (crop and
/// district are free text, unlike problem type), so both the feed's filter
/// chips and the create-post selectors offer this small curated list matching
/// what's in the seed data. Shared so a post can never be created with a tag
/// the feed has no chip to filter by.
const kCommunityCrops = ['Wheat', 'Cotton', 'Onion', 'Sugarcane', 'Soybean', 'Rice', 'Mustard', 'Grapes', 'Okra'];
const kCommunityDistricts = ['Pune', 'Aurangabad', 'Nashik', 'Kolhapur', 'Solapur'];

// Limits mirror the server's validation (communityController.createPost).
const kPostTitleMin = 5;
const kPostTitleMax = 150;
const kPostContentMin = 5;
const kPostContentMax = 3000;

// 110 Zimbabwean hustles. Format 'Name:startupUSD'. Startup costs and the
// needs/whereToSell/proTip text are category-level placeholders: edit freely.
const _raw = <String, List<String>>{
  'Food & Drinks': ['Maputi:15', 'Freezit:10', 'Maheu:15', 'Fat cakes:20', 'Samosas:25', 'Boiled eggs:20', 'Braai:60', 'Sadza lunch:40', 'Peanut butter:30', 'Biltong:50', 'Fruit salad:20', 'Juice:25', 'Cake baking:40', 'Bread:50', 'Chips:60', 'Nzungu:15', 'Popcorn:20', 'Roasted maize:15', 'Ice cream:80', 'Tea & scones:30'],
  'Retail & Vending': ['Tuckshop:200', 'Airtime/EcoCash:50', 'Bhero clothes:100', 'Baby clothes:80', 'Bags/wigs:80', 'Phone accessories:60', 'Shoes:100', 'Perfumes:60', 'Kitchen utensils:70', 'Chemicals:50', 'Gas:150', 'Water:100', 'Eggs:60', 'Vegetables:30', 'Fruit:30', 'Hardware:300', 'Phones:200', 'Cosmetics:70', 'Stationery:60', 'School uniforms:120'],
  'Skills & Services': ['Car wash:40', 'Barber:80', 'Salon braiding:50', 'Nail tech:60', 'Tailor:150', 'Builder:100', 'Painter:80', 'Tiler:120', 'Welder:300', 'Carpentry:250', 'Plumbing:150', 'Solar installation:200', 'Phone repair:100', 'Shoe repair:40', 'Mechanic:300', 'DSTV installation:100', 'Photography:250', 'DJ:300', 'Decoration:150', 'Laundry:100', 'Gardening:40', 'Tutoring:10', 'CV typing:30', 'Brick moulding:60', 'Electrician:150', 'Hair weaving:60', 'Makeup artist:80', 'Videography:300', 'Upholstery:150', 'Domestic cleaning:30'],
  'Farming & Agro': ['Broiler chickens:150', 'Roadrunner:120', 'Layers:300', 'Veg garden:50', 'Mushroom:60', 'Rabbit:100', 'Goats:250', 'Honey:150', 'Fish:300', 'Firewood:30', 'Pigs:300', 'Tomatoes:80', 'Maize seed:100', 'Irrigation pipes:150', 'Compost:40'],
  'Transport & Digital': ['Mushikashika:500', 'Courier:100', 'WhatsApp marketing:10', 'Logo design:20', 'Printing T-shirts:200', 'Solar charging:80', 'Delivery bike:300', 'Tuk-tuk:1500', 'Social media management:10', 'Web design:30', 'Online shop:20', 'Data bundles reseller:50', 'Printing & lamination:300', 'Photocopying:300', 'Freelance writing:10'],
  'Bonus': ['Tent & chairs hire:500', 'Sound system hire:600', 'Event MC:20', 'Funeral services:300', 'Baby sitting:5', 'Pet care:20', 'Scrap metal:30', 'Recycling:40', 'Second-hand books:50', 'Cooking oil refill:80'],
};

const _defaults = <String, List<String>>{
  'Food & Drinks': ['Ingredients, clean container, cooler/stove, hygiene basics', 'Schools, bus stops, markets, offices', 'Keep portions consistent and be there at the same time daily.'],
  'Retail & Vending': ['Starting stock, table or shop space, a notebook for stock', 'Township corners, ranks, WhatsApp groups', 'Buy in bulk with friends to cut cost, track fast movers.'],
  'Skills & Services': ['Tools of the trade, transport, a few samples of your work', 'Referrals, WhatsApp Status, door to door', 'Photograph every job and post it. Your work is your advert.'],
  'Farming & Agro': ['Land or space, inputs, water, basic training', 'Local markets, restaurants, neighbours, schools', 'Start small, learn, then scale. Keep records of losses.'],
  'Transport & Digital': ['Vehicle or phone/laptop, data, a clear service menu', 'Online groups, shops, businesses, ranks', 'Be reliable and reply fast. Repeat customers are the business.'],
  'Bonus': ['Equipment or know-how, a way to reach customers', 'Events, churches, funerals, word of mouth', 'Take deposits to protect yourself from no-shows.'],
};

Map<String, dynamic> _mk(String s, String cat) {
  final p = s.split(':'), d = _defaults[cat]!;
  return {'name': p[0], 'category': cat, 'needs': d[0], 'startup': int.parse(p[1]), 'whereToSell': d[1], 'proTip': d[2]};
}

final List<Map<String, dynamic>> businessIdeas = [
  for (final e in _raw.entries) for (final s in e.value) _mk(s, e.key)
];

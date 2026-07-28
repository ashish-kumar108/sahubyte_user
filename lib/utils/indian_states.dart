const indianStates = <String>[
  'Andaman and Nicobar Islands',
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chandigarh',
  'Chhattisgarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jammu and Kashmir',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Ladakh',
  'Lakshadweep',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Puducherry',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
];

String? matchIndianState(String? value) {
  final cleaned = value?.trim().toLowerCase();
  if (cleaned == null || cleaned.isEmpty) return null;

  const aliases = <String, String>{
    'national capital territory of delhi': 'Delhi',
    'nct of delhi': 'Delhi',
    'orissa': 'Odisha',
    'uttaranchal': 'Uttarakhand',
    'pondicherry': 'Puducherry',
  };
  final alias = aliases[cleaned];
  if (alias != null) return alias;

  for (final state in indianStates) {
    if (state.toLowerCase() == cleaned) return state;
  }
  return null;
}

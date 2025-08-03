const testHairValues = async () => {
  console.log('🔍 Testing Hair Values for Adventurer...\n');
  
  // Test different hair value patterns
  const hairValues = [
    'short', 'long', 'curly', 'straight', 'bald', 'none',
    'shortHair', 'longHair', 'curlyHair',
    'variant01', 'variant1', '01', '1',  
    'hairShort', 'hairLong', 'hairCurly',
    'shortHair01', 'longHair01',
    'short01', 'long01',
    'base', 'default'
  ];
  
  for (let i = 0; i < hairValues.length; i++) {
    const hairValue = hairValues[i];
    const url = `https://api.dicebear.com/9.x/adventurer/svg?seed=test&hair=${hairValue}`;
    
    console.log(`Test ${i + 1}: hair=${hairValue}`);
    try {
      const response = await fetch(url);
      if (response.ok) {
        const content = await response.text();
        console.log(`  ✅ SUCCESS - Content length: ${content.length}`);
      } else {
        console.log(`  ❌ Failed - Status: ${response.status}`);
      }
    } catch (error) {
      console.log(`  ❌ Network error: ${error.message}`);
    }
  }
};

testHairValues();
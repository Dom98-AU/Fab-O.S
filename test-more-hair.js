const testMoreHair = async () => {
  console.log('🔍 Testing More Hair Values...\n');
  
  // Test more hair values based on the pattern we found
  const hairValues = [
    'short01', 'short02', 'short03', 'short04', 'short05',
    'long01', 'long02', 'long03', 'long04', 'long05',
    'curly01', 'curly02', 'curly03',
    'wavy01', 'wavy02', 'wavy03',
    'straight01', 'straight02'
  ];
  
  const successValues = [];
  
  for (const hairValue of hairValues) {
    const url = `https://api.dicebear.com/9.x/adventurer/svg?seed=test&hair=${hairValue}`;
    
    try {
      const response = await fetch(url);
      if (response.ok) {
        successValues.push(hairValue);
        console.log(`✅ ${hairValue}`);
      } else {
        console.log(`❌ ${hairValue}`);
      }
    } catch (error) {
      console.log(`❌ ${hairValue} (network error)`);
    }
  }
  
  console.log(`\n📋 Successful hair values for Adventurer: ${successValues.join(', ')}`);
};

testMoreHair();
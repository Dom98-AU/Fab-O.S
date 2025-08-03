const testVariants = async () => {
  console.log('🔍 Testing More Variant Values...\n');
  
  const testUrls = [
    'https://api.dicebear.com/9.x/adventurer/svg?seed=test&eyes=variant01',
    'https://api.dicebear.com/9.x/adventurer/svg?seed=test&eyes=variant02',
    'https://api.dicebear.com/9.x/adventurer/svg?seed=test&eyes=variant26',
    'https://api.dicebear.com/9.x/adventurer/svg?seed=test&mouth=variant01',
    'https://api.dicebear.com/9.x/adventurer/svg?seed=test&mouth=variant30',
    'https://api.dicebear.com/9.x/adventurer/svg?seed=test&hair=variant01',
    'https://api.dicebear.com/9.x/adventurer/svg?seed=test&hair=variant05',
    'https://api.dicebear.com/9.x/adventurer/svg?seed=test&eyes=variant01&mouth=variant01&hair=variant01',
  ];
  
  for (let i = 0; i < testUrls.length; i++) {
    const url = testUrls[i];
    const params = url.split('?')[1];
    
    console.log(`Test ${i + 1}: ${params}`);
    try {
      const response = await fetch(url);
      console.log(`  Status: ${response.status} ${response.statusText}`);
      
      if (response.ok) {
        const content = await response.text();
        console.log(`  ✅ Success - Content length: ${content.length}`);
      } else {
        const errorText = await response.text();
        console.log(`  ❌ Failed - Error: ${errorText.substring(0, 100)}`);
      }
    } catch (error) {
      console.log(`  ❌ Network error: ${error.message}`);
    }
  }
};

testVariants();
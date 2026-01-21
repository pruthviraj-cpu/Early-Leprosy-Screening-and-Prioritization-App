// test-password.js
import dotenv from 'dotenv';
import { supabase } from './src/config/supabase.js';

dotenv.config();

async function testPassword() {
  const tests = [
    {
      email: 'verified1769017639729@gmail.com',
      password: 'VerifiedPassword123!'
    },
    {
      email: 'verified1769017639729@gmail.com',
      password: 'VerifiedPassword123' // missing !
    },
    {
      email: 'verified1769017639729@gmail.com',
      password: 'verifiedpassword123!' // lowercase
    }
  ];
  
  for (const test of tests) {
    console.log(`\nTesting: ${test.email} with password: "${test.password}"`);
    
    const { error } = await supabase.auth.signInWithPassword({
      email: test.email,
      password: test.password
    });
    
    if (error) {
      console.log(`❌ Failed: ${error.message}`);
    } else {
      console.log(`✅ Success!`);
      console.log(`✅ Correct password is: "${test.password}"`);
      break;
    }
  }
}

testPassword();
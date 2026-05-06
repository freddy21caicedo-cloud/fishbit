
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://oakovawlwjpnoydpwtam.supabase.co';
const supabaseAnonKey = 'sb_publishable_7E0yEoAyf0mlEVFSLg9cPw_Buig1574';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function checkSchema() {
  const { data, error } = await supabase
    .from('siembra_details')
    .select('*')
    .limit(1);
  
  if (error) {
    console.error("Error fetching siembra_details:", error);
  } else {
    if (data && data.length > 0) {
      console.log("Columns in siembra_details:", Object.keys(data[0]));
    } else {
      // If no data, try to fetch column names from a different method if possible
      // But usually this is enough if there is at least one row.
      // Let's try to insert a fake row with a non-existent column to see the error message
      const { error: insertError } = await supabase.from('siembra_details').insert([{ unit_id: 'test' }]);
      console.log("Insert Test Result:", insertError?.message);
    }
  }
}

checkSchema();

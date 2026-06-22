const axios = require('axios');

(async () => {
  try {
    const { data } = await axios.get('https://api.apis.net.pe/v1/dni?numero=77436156');
    console.log('apis.net.pe result:', data);
  } catch (err) {
    console.log('apis.net.pe failed:', err.message);
  }
})();

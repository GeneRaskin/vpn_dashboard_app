async function fetchConfig() {
  const email = document.getElementById('email').value;
  const output = document.getElementById('output');
  output.textContent = "Loading...";

  try {
    const res = await fetch(`${api_url}/config?email=$${encodeURIComponent(email)}`);
    const data = await res.json();

    if (!res.ok) {
      output.textContent = `Error: $${data.error}`;
    } else {
      output.textContent = JSON.stringify(data, null, 2);
    }
  } catch (err) {
    output.textContent = `Error: $${err.message}`;
  }
}
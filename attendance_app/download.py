import urllib.request

url = 'https://upload.wikimedia.org/wikipedia/en/thumb/8/8c/Don_Bosco_Technical_College_Cebu_seal.svg/512px-Don_Bosco_Technical_College_Cebu_seal.svg.png'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'})

with urllib.request.urlopen(req) as response, open('e:/attendance_backend/attendance_app/assets/images/logo.png', 'wb') as out_file:
    data = response.read()
    out_file.write(data)

print("success")

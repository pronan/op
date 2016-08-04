from http.server import BaseHTTPRequestHandler, HTTPServer
import time
import os

hostName = "wdksw.com"
hostPort = 9000
# yeah, baby.
class MyServer(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(bytes("<html><head><title>Title goes here.</title></head>", "utf-8"))
        self.wfile.write(bytes("<body><p>This is a test.</p>", "utf-8"))
        self.wfile.write(bytes("<p>You accessed path: %s</p>" % self.path, "utf-8"))
        self.wfile.write(bytes("</body></html>", "utf-8"))
    def do_POST(self):
        for l in os.popen('git --git-dir=/root/op/.git --work-tree=/root/op pull'):
            print(l)
        for l in os.popen('nginx -p /root/op -c /root/op/conf/devu -s reload'):
            print(l)
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()

myServer = HTTPServer((hostName, hostPort), MyServer)
print(time.asctime(), "Server Starts - %s:%s" % (hostName, hostPort))

try:
    myServer.serve_forever()
except KeyboardInterrupt:
    pass

myServer.server_close()
print(time.asctime(), "Server Stops - %s:%s" % (hostName, hostPort))
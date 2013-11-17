require 'socket'
require "uri"

WEB_ROOT = "./public"

CONTENT_TYPE_MAPPING = {
  'html' => 'text/html',
  'txt' => 'text/plain',
  'png' => 'image/png',
  'jpg' => 'image/jpeg'
}

DEFAULT_CONTENT_TYPE = 'application/octet-stream'

def content_type(path)
  ext = File.extname(path).split(".").last
  CONTENT_TYPE_MAPPING.fetch(ext, DEFAULT_CONTENT_TYPE)
end

def requested_file(request_name)
  request_URI = request_name.split(" ")[1]
  path = URI.unescape(URI(request_URI).path)

  clean = []

  parts = path.split("/")
  parts.each do |part|
    next if part.empty? || part == '.'
    part == '..' ? clean.pop : clean << part
  end

  File.join(WEB_ROOT, path)
end

server = TCPServer.new 1337

puts "Igor, recieve the visitors coming in on port 1337"

loop do
  client = server.accept

  request = client.gets
  puts request

  path = requested_file(request)
  path = File.join(path, 'index.html') if File.directory?(path)

  if File.exist?(path) && !File.directory?(path)
    File.open(path, "rb") do |file|

      client.puts "HTTP/1.1 200 OK"
      client.puts "Content-Type: #{content_type(file)}"
      client.puts "Content-Length: #{file.size}"
      client.puts "Connection: close"
      client.puts

      IO.copy_stream(file, client)
    end
  else
    message = "File not found/n"

    client.puts "HTTP/1.1 404 Not Found"
    client.puts "Content-Type: text/plain"
    client.puts "Content-Length: #{message.size}"
    client.puts "Connection: close"
    client.puts
    client.puts message
  end
  client.close

end
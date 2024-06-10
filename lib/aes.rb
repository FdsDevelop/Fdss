require 'openssl'
require 'net/http'
module Aes
  def encrypt(data)
    cipher = OpenSSL::Cipher.new('AES-256-CBC')
    cipher.encrypt
    cipher.key = Rails.application.config.fdss.secret
    encrypted = cipher.update(data) + cipher.final
    Base64.strict_encode64(encrypted)
  end

  # 解密方法
  def decrypt(encrypted_data)
    cipher = OpenSSL::Cipher.new('AES-256-CBC')
    cipher.decrypt
    cipher.key = Rails.application.config.fdss.secret
    decrypted = cipher.update(Base64.strict_decode64(encrypted_data)) + cipher.final
    decrypted
  end

  def encrypt_post_request(uri,data,timeout)
    url = URI.parse(uri)
    http = Net::HTTP.new(url.host, url.port)
    http.read_timeout = timeout
    request = Net::HTTP::Post.new(url.path)
    serial = Rails.application.config.fdss.serial
    payload_encrypt = encrypt({time_stamp: Time.current.to_i, data: data, sign: Rails.application.config.fdss.sign}.to_json)
    request_body = {serial: serial, payload:payload_encrypt}
    request.set_form_data(request_body)
    http.request(request)
  end
end
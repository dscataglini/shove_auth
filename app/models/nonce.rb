class Nonce < ActiveRecord::Base
  before_validation :uid_populator
  belongs_to :account, :foreign_key => :user_id
  
  [:nonce, :session_secret, :sid].each do |a|
    validates_uniqueness_of a, :allow_nil=>true
    validates_length_of a, :is=>40, :allow_nil=>true
  end
  validates_numericality_of :user_id, :allow_nil=>true
  
  # create-time methods
  
  def uid_populator
    self.nonce ||= Nonce.rand_bytes
    self.sid ||= Nonce.rand_bytes
  end
  
  def load_user(user, hmac)
    return false if self.user_id
    check = Nonce.hmac(user.digest, "PUT /session/#{sid} #{nonce}")
    return false unless check == hmac
    self.user_id = user.id
    self.nonce = nil
    self.session_secret = Nonce.rand_bytes
    return user
  end
  
  # inspector methods
  
  def state
    return self.user_id ? :authenticated : :not_authenticated
  end
  
  # serialization methods
  
  def to_xml(o = {})
    super(o.merge(serialization_options))
  end
  
  def to_json(o = {})
    super(o.merge(serialization_options))
  end
  
  def serialization_options
    {:methods=>[:state], :except=>[:id, :user_id]}
  end
  
  # class methods
  
  # forty random bytes
  def self.rand_bytes
    Base64.encode64(OpenSSL::Random.random_bytes(30)).chomp.tr('+/','-_')
  end
  
  def self.load_nonce(sid, username = nil, hmac = nil)
    return false unless username && hmac
    user = Account.find_by_username(username)
    return false unless user
    nonce = find_by_sid(sid)
    return false unless nonce
    r = nonce.load_user(user, hmac)
    if r
      nonce.save
      return nonce
    end
    return false
  end
  
  def self.hmac(secret, message)
    return OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('SHA1'), secret, message)
  end
  
  def self.find_outdated
    self.find(:all, :conditions=>['created_at < ?', 7.days.ago])
  end
end

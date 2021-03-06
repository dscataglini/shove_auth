class SessionController < ApplicationController
  def create
    n = Nonce.create
    respond_to do |wants|
      wants.json { render :json=>n.to_json }
      wants.xml { render :xml=>n.to_xml }
    end
  end

  def update
    session = params[:session] || {}
    n = Nonce.load_nonce(params[:id], session[:username], session[:hmac])
    
    unless n
      render(:text=>'400 Bad Request', :status=>403)
      return
    end
    
    
    respond_to do |wants|
      wants.json { render :json=>n.to_json }
      wants.xml { render :xml=>n.to_xml }
    end
  end

  def show
    sid = params[:id]
    n = Nonce.find_by_sid(sid)
    if n.nil?
      render(:text=>'404 Not Found', :status=>404) 
      return
    end
    
    expected_hmac = hmac(n.session_secret, "GET /session/#{sid} #{sid}")
    
    if n.state == :not_authenticated || params[:hmac] != expected_hmac
      render(:text=>'403 Forbidden', :status=>403)
      return
    end
    
    
    respond_to do |wants|
      wants.json { render :json=>n.to_json }
      wants.xml { render :xml=>n.to_xml }
    end
  end
  
  def destroy
    sid = params[:id]
    n = Nonce.find_by_sid(sid)
    expected
  end

end

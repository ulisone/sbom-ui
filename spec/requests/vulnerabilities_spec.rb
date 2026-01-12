require 'rails_helper'

RSpec.describe "Vulnerabilities", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/vulnerabilities/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/vulnerabilities/show"
      expect(response).to have_http_status(:success)
    end
  end

end

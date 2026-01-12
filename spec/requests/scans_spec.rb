require 'rails_helper'

RSpec.describe "Scans", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/scans/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/scans/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/scans/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/scans/create"
      expect(response).to have_http_status(:success)
    end
  end

end

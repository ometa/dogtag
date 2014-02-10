require 'spec_helper'

describe ApplicationController do

  # Magic rspec Anonymous Controller Testing
  # https://relishapp.com/rspec/rspec-rails/v/2-4/docs/controller-specs/anonymous-controller
  controller(ApplicationController) do
    def csv_gen
      respond_to do |format|
        format.csv { render :csv => params[:obj] || 'foo', :filename => params[:filename] }
      end
    end
  end

  describe "csv renderer" do
    before do
      routes.draw { get "csv_gen" => "anonymous#csv_gen" }
      request.accept = Mime::CSV
    end

    context "filename parameter" do
      it "sets if it is passed" do
        get :csv_gen, :filename => 'foo'
        response.header['Content-Disposition'].should == 'attachment; filename=foo.csv'
      end

      it "defaults to 'data' if it is not passed" do
        get :csv_gen
        response.header['Content-Disposition'].should == 'attachment; filename=data.csv'
      end
    end

    it "if the object responds to to_csv render" do
      passed_obj = ['a','e','b','f','c','g']
      get :csv_gen, :obj => passed_obj
      expect(response.body).to eq(passed_obj.to_csv)
    end

    it "if the object does not have a to_csv method it will call to_s instead" do
      get :csv_gen, :obj => 'foobar'
      expect(response.body).to eq('foobar')
    end

    it "sets the mime type" do
      get :csv_gen
      expect(response.content_type).to eq(Mime::CSV)
    end
  end

end

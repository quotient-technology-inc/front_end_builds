require_dependency "front_end_builds/application_controller"

module FrontEndBuilds
  class BuildsController < ApplicationController
    before_filter :set_app!, only: :create
    respond_to :json

    def index
      builds = FrontEndBuilds::Build.where(app_id: params[:app_id])
      respond_with({
        builds: builds.map(&:serialize)
      })
    end

    def create
      build = @app.builds.new(build_create_params)

      if build.save
        build.fetch!
        build.activate! if build.automatic_activiation?
        head :ok

      else
        render(
          text: 'Could not create the build: ' + build.errors.full_messages.to_s,
          status: :unprocessable_entity
        )
      end
    end

    def show
      build = FrontEndBuilds::Build.find(params[:id])
      respond_with({
        build: build.serialize
      })
    end

    private

    def set_app!
      @app = find_app
      if @app.nil?
        render(
          text: 'That app name/API combination was not found.',
          status: :unprocessable_entity
        )
      end
    end

    def build_create_params
      params.permit(
        :branch,
        :sha,
        :job,
        :endpoint
      )
    end

    def find_app
      FrontEndBuilds::App.where(
        name: params[:app_name],
        api_key: params[:api_key]
      ).limit(1).first
    end
  end
end

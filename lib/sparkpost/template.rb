require 'net/http'
require 'uri'
require_relative 'request'
require_relative 'helpers'
require_relative 'exceptions'

module SparkPost
  class Template
    include Request
    include Helpers

    def initialize(api_key, api_host)
      @api_key = api_key
      @api_host = api_host
      @base_endpoint = "#{@api_host}/api/v1/templates"
    end

    def create(id, from = nil, subject = nil, html = nil, **options)
      data = deep_merge(
        payload_from_args(id, from, subject, html),
        payload_from_options(options)
      )
      send_payload(data)
    end

    def update(id, from = nil, subject = nil, html = nil, **options)
      params = {}
      copy_value(options, :update_published, params, :update_published)
      data = deep_merge(
        payload_from_args(nil, from, subject, html),
        payload_from_options(options)
      )
      send_payload(data, endpoint(id, params), 'PUT')
    end

    def delete(id)
      send_payload(nil, endpoint(id), 'DELETE')
    end

    def get(id, draft = nil)
      params = {}
      params[:draft] = draft unless draft.nil?
      send_payload(nil, endpoint(id, params), 'GET')
    end

    def list
      send_payload(nil, endpoint, 'GET')
    end

    def preview(id, substitution_data, draft = nil)
      params = {}
      params[:draft] = draft unless draft.nil?
      send_payload(
        { substitution_data: substitution_data },
        endpoint("#{id}/preview", params), 'POST'
      )
    end

    def send_payload(data = {}, url = endpoint, method = 'POST')
      request(url, @api_key, data, method)
    end

    private

    def payload_from_args(id, from, subject, html)
      model = { content: {}, options: {} }

      model[:id] = id unless id.nil?
      model[:content][:from] = from unless from.nil?
      model[:content][:subject] = subject unless subject.nil?
      model[:content][:html] = html unless html.nil?

      model
    end

    def payload_from_options(**options)
      model = { content: { from: {} }, options: {} }

      # Mapping optional arguments to root
      [
        [:name, :name],
        [:id, :id],
        [:description, :description],
        [:published, :published]
      ].each { |skey, dkey| copy_value(options, skey, model, dkey) }

      # Mapping optional arguments to options
      [
        [:track_opens, :open_tracking],
        [:track_clicks, :click_tracking],
        [:is_transactional, :transactional]
      ].each { |skey, dkey| copy_value(options, skey, model[:options], dkey) }

      # Mapping optional arguments to content
      [
        [:html, :html],
        [:text, :text],
        [:subject, :subject],
        [:reply_to, :reply_to],
        [:custom_headers, :headers]
      ].each { |skey, dkey| copy_value(options, skey, model[:content], dkey) }

      # Mapping optional arguments to sender information
      [
        [:from_email, :email],
        [:from_name, :name]
      ].each do |skey, dkey|
        copy_value(options, skey, model[:content][:from], dkey)
      end

      model
    end
  end
end

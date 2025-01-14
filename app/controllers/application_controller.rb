# frozen_string_literal: true

require 'exceptions'

# General controller to include all-encompassing behavior
class ApplicationController < ActionController::API
  include ActionController::Helpers
  include DefaultHeaders
  include Pundit
  include Authentication
  include ExceptionNotifierCustomData
  include Metadata
  include Pagination
  include Collection
  include Rendering
  include Parameters

  def openapi
    send_file Rails.root.join('swagger/v1/openapi.v3.yaml')
  end

  def pundit_scope
    Pundit.policy_scope(current_user, resource)
  end

  rescue_from ActiveRecord::RecordNotUnique do |error|
    render_error "Duplicate record: #{error.message[/Key \(.+\).+\./]}",
                 status: :conflict
  end

  rescue_from Pundit::NotAuthorizedError do
    render_error 'You are not authorized to access this action.',
                 status: :forbidden
  end

  rescue_from ActiveRecord::RecordNotFound do |error|
    logger.info "#{error.message} (#{error.class})"
    render_error "#{error.model} not found with ID #{error.id}",
                 status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |error|
    logger.info "#{error.message} (#{error.class})"
    if error.record
      render_model_errors(error.record)
    else
      render_error(error.message)
    end
  end

  rescue_from ActionController::ParameterMissing do |error|
    logger.info "#{error.message} (#{error.class})"
    render_error "Parameter missing: #{error.message}",
                 status: :unprocessable_entity
  end

  rescue_from StrongerParameters::InvalidParameter do |error|
    logger.info "#{error.message} (#{error.class})"
    render_error error.message,
                 status: :unprocessable_entity
  end

  rescue_from ::Exceptions::InvalidSortingDirection do |error|
    logger.info "#{error.message} (#{error.class})"
    render_error error.message,
                 status: :unprocessable_entity
  end

  rescue_from ::Exceptions::InvalidSortingColumn do |error|
    logger.info "#{error.message} (#{error.class})"
    render_error error.message,
                 status: :unprocessable_entity
  end

  protected

  def audit_success(msg)
    Rails.logger.audit_success(msg)
  end
end

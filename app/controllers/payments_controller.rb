class PaymentsController < ApplicationController
  before_action(:authenticate_user!)
  before_action(:set_payment, only: [:show, :update, :destroy])
  before_action(:check_permissions, except: [:index])

	def index
    payments = Payment.includes(:service)
      .with_attached_attachments
      .by_status(filter_params[:status])
      .by_payment_date_start(filter_params[:payment_date_start])
      .by_payment_date_end(filter_params[:payment_date_end])
      .by_expiration_date_start(filter_params[:expiration_date_start])
      .by_expiration_date_end(filter_params[:expiration_date_end])
      .by_patient_id(filter_params[:patient_id])
      .order(order_by)
      .allowed

    total = payments.count

    if params[:page].present?
      payments = payments.page(params[:page]).per(params[:per_page] || 30)
    end

		render_json_success({
      payments: payments.map(&:show),
      total: total
    })
	end

  def show
    render_json_success({ payment: @payment.show })
  end

  def create
    @payment = Payment.new(payment_params)

    if @payment.save
      render_json_success({ payment: @payment.show })
    else
      render_json_errors(@payment.errors)
    end
  end

  def update
     if @payment.update(payment_params)
      render_json_success({ payment: @payment.show })
    else
      render_json_errors(@payment.errors)
    end
  end

  def destroy
    if @payment.destroy
      render_json_success({ payment: @payment.show })
    else
      render_json_errors(@payment.errors)
    end
  end

  private

  def check_permissions
    case params[:action]
    when "create"
      current_profile = User.current.profile
      return render_not_allowed() unless current_profile.admin? || current_profile.therapist?
      if current_profile.therapist?
        service = Service.find_by_id(params.dig(:payment, :service_id))
        return render_not_allowed() if service.nil? || service.therapist_id != current_profile.id
      end
    when "update", "destroy", "show"
      return render_not_allowed() if !@payment.allowed?
    end
  end

  def set_payment
    @payment = Payment.find_by_id(params[:id])

    return render_not_found(Payment) if @payment.nil?
  end

  def filter_params
    return {} unless params[:payments].present?

    params.permit(payments: [
      :payment_date_start,
      :payment_date_end,
      :expiration_date_start,
      :expiration_date_end,
      :patient_id,
      :status
    ])[:payments].to_h.symbolize_keys
  end

  def payment_params
    params.require(:payment)
      .permit(
        :value,
        :expiration_date,
        :payment_date,
        :payment_method,
        :service_id,
        attachments: []
      ).to_h.symbolize_keys
  end

  def order_by
    case params[:order_by]
    when "expiration_date_asc"
      { expiration_date: :asc }
    when "expiration_date_desc"
      { expiration_date: :desc }
    when "payment_date_asc"
      { payment_date: :asc }
    when "payment_date_desc"
      { payment_date: :desc }
    else
      { expiration_date: :desc }
    end
  end
end

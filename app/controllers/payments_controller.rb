class PaymentsController < ApplicationController
  before_action(:authenticate_user!)
  before_action(:set_payment, only: [:show, :update, :destroy])
  before_action(:check_permissions, except: [:index, :create])

	def index
    payments = Payment.by_status(filter_params[:status])
      .by_payment_date_start(filter_params[:payment_date_start])
      .by_payment_date_end(filter_params[:payment_date_end])
      .by_expiration_date_start(filter_params[:expiration_date_start])
      .by_expiration_date_end(filter_params[:expiration_date_end])
      .by_patient_id(filter_params[:patient_id])
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
        :service_id
      ).to_h.symbolize_keys
  end
end

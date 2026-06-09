class PaymentsController < ApplicationController
  before_action(:authenticate_user!)
  before_action(:set_payment, only: [:show, :update, :destroy])
  before_action(:check_permissions, except: [:index, :status_chart, :monthly_chart])

	def index
    filtered = Payment.includes(:service)
      .with_attached_attachments
      .by_status(filter_params[:status])
      .by_payment_date_start(filter_params[:payment_date_start])
      .by_payment_date_end(filter_params[:payment_date_end])
      .by_expiration_date_start(filter_params[:expiration_date_start])
      .by_expiration_date_end(filter_params[:expiration_date_end])
      .by_patient_id(filter_params[:patient_id])
      .allowed

    total = Payment.allowed.count
    total_filtered = filtered.count
    total_received = filtered.where.not(payment_date: nil).sum(:value)
    total_to_receive = filtered.where(payment_date: nil).sum(:value)

    payments = filtered.order(order_by)

    if params[:page].present?
      payments = payments.page(params[:page]).per(params[:per_page] || 30)
    end

		render_json_success({
      payments: payments.map(&:show),
      total: total,
      total_filtered: total_filtered,
      total_received: total_received,
      total_to_receive: total_to_receive
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

  # Distribuição dos pagamentos por status (não é afetada pelos filtros do painel).
  def status_chart
    payments = Payment.allowed

    status_chart = [:paid, :overdue, :unpaid].map do |status|
      { status: status, count: payments.by_status(status).count }
    end

    render_json_success({ status_chart: status_chart })
  end

  # Pagamentos recebidos x a receber por mês nos últimos 12 meses
  # (não é afetado pelos filtros do painel).
  def monthly_chart
    start_date = Date.current.beginning_of_month.prev_month(11)
    payments = Payment.allowed.where("expiration_date >= ?", start_date)

    received = payments.where.not(payment_date: nil)
    to_receive = payments.where(payment_date: nil)

    received_value = group_by_month(received, :sum)
    received_count = group_by_month(received, :count)
    to_receive_value = group_by_month(to_receive, :sum)
    to_receive_count = group_by_month(to_receive, :count)

    monthly_chart = (0..11).map do |offset|
      month = start_date.next_month(offset).strftime("%Y-%m")
      {
        month: month,
        received: (received_value[month] || 0).to_f,
        received_count: received_count[month] || 0,
        to_receive: (to_receive_value[month] || 0).to_f,
        to_receive_count: to_receive_count[month] || 0
      }
    end

    render_json_success({ monthly_chart: monthly_chart })
  end

  private

  def group_by_month(scope, operation)
    grouped = scope.group(Arel.sql("DATE_TRUNC('month', expiration_date)"))
    grouped = operation == :sum ? grouped.sum(:value) : grouped.count
    grouped.transform_keys { |date| date.to_date.strftime("%Y-%m") }
  end

  def check_permissions
    case params[:action]
    when "create"
      current_profile = User.current.profile
      if !current_profile.admin? && params.dig(:service, :therapist_id) != current_profile.id
        return render_not_allowed()
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

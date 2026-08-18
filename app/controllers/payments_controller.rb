class PaymentsController < ApplicationController
  MONTHLY_CHART_MONTHS = 12

  before_action(:authenticate_user!)
  before_action(:set_payment, only: [ :show, :update, :destroy ])
  before_action(:check_permissions, except: [ :index, :status_chart, :monthly_chart ])

  sortable(
    "expiration_date_asc" => { expiration_date: :asc },
    "expiration_date_desc" => { expiration_date: :desc },
    "payment_date_asc" => { payment_date: :asc },
    "payment_date_desc" => { payment_date: :desc },
    default: { expiration_date: :desc }
  )

  def index
    filtered = filtrated_payments
      .includes(service: [ :patient, :therapist, :medical_record, :payment ])
      .with_attached_attachments

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
    remove_ids = params.require(:payment).permit(remove_attachment_ids: [])[:remove_attachment_ids] || []
    @payment.attachments.where(id: remove_ids).find_each(&:purge) if remove_ids.any?

    attributes = payment_params
    new_attachments = attributes.delete(:attachments)

    if @payment.update(attributes)
      @payment.attachments.attach(new_attachments) if new_attachments.present?
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

  # Distribuição por status dentro do conjunto filtrado do painel.
  def status_chart
    payments = filtrated_payments

    status_chart = [ :paid, :overdue, :unpaid ].map do |status|
      { status: status, count: payments.by_status(status).count }
    end

    render_json_success({ status_chart: status_chart })
  end

  # Pagamentos recebidos x a receber por mês (até 12 meses) dentro do conjunto
  # filtrado do painel.
  def monthly_chart
    payments = filtrated_payments
    start_date, months = monthly_chart_range(payments)
    payments = payments.where(expiration_date: start_date..)

    received = payments.where.not(payment_date: nil)
    to_receive = payments.where(payment_date: nil)

    received_value = group_by_month(received, :sum)
    received_count = group_by_month(received, :count)
    to_receive_value = group_by_month(to_receive, :sum)
    to_receive_count = group_by_month(to_receive, :count)

    monthly_chart = (0...months).map do |offset|
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

  # Conjunto filtrado do painel — base comum da listagem e dos gráficos.
  def filtrated_payments
    Payment.filtrate(filter_params)
  end

  # A janela do gráfico mensal acompanha o conjunto filtrado: termina no
  # vencimento mais recente e recua até o mais antigo, no máximo 12 meses.
  # Sem resultados, mantém os 12 meses que terminam no mês atual.
  def monthly_chart_range(payments)
    last_date = payments.maximum(:expiration_date)

    if last_date.blank?
      start_date = Date.current.beginning_of_month.prev_month(MONTHLY_CHART_MONTHS - 1)
      return [ start_date, MONTHLY_CHART_MONTHS ]
    end

    last_month = last_date.beginning_of_month
    oldest_month = payments.minimum(:expiration_date).beginning_of_month
    start_month = [ oldest_month, last_month.prev_month(MONTHLY_CHART_MONTHS - 1) ].max

    months = (last_month.year - start_month.year) * 12 + (last_month.month - start_month.month) + 1

    [ start_month, months ]
  end

  def group_by_month(scope, operation)
    grouped = scope.group(Arel.sql("DATE_TRUNC('month', payments.expiration_date)"))
    grouped = operation == :sum ? grouped.sum(:value) : grouped.count
    grouped.transform_keys { |date| date.to_date.strftime("%Y-%m") }
  end

  def check_permissions
    case params[:action]
    when "create"
      current_profile = Current.profile
      if !current_profile.admin? && params.dig(:service, :therapist_id) != current_profile.id
        render_not_allowed()
      end
    when "update", "destroy", "show"
      authorize_record!(@payment)
    end
  end

  def set_payment
    @payment = Payment.find_by_id(params[:id])

    render_not_found(Payment) if @payment.nil?
  end

  def filter_params
    nested_filter_params(:payments, [
      :payment_date_start,
      :payment_date_end,
      :expiration_date_start,
      :expiration_date_end,
      :patient_id,
      :status
    ])
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
end

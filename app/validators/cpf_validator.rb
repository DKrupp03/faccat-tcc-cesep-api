# Valida CPF pelos dois dígitos verificadores. O front já aplica a máscara
# (000.000.000-00), então a pontuação é ignorada aqui.
class CpfValidator < ActiveModel::EachValidator
  LENGTH = 11

  def validate_each(record, attribute, value)
    return if valid_cpf?(digits_of(value))

    record.errors.add(attribute, options[:message] || :invalid_cpf)
  end

  private

  def digits_of(value)
    value.to_s.gsub(/\D/, "")
  end

  def valid_cpf?(digits)
    return false unless digits.length == LENGTH
    # Sequências repetidas (111.111.111-11) passam no cálculo, mas não existem.
    return false if digits.chars.uniq.size == 1

    check_digit(digits, 9) == digits[9].to_i && check_digit(digits, 10) == digits[10].to_i
  end

  # Soma ponderada dos `size` primeiros dígitos, com pesos decrescentes.
  def check_digit(digits, size)
    sum = size.times.sum { |i| digits[i].to_i * (size + 1 - i) }
    remainder = (sum * 10) % LENGTH

    remainder == 10 ? 0 : remainder
  end
end

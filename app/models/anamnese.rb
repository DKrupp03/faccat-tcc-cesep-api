class Anamnese < ApplicationRecord
  belongs_to(:patient, class_name: "Profile")
  belongs_to(:therapist, class_name: "Profile")

  validates(:anamnese_type, presence: true)
  validates(:anamnese_data, presence: true)

  enum(:anamnese_type, { child: 0, adolescent: 1, adult: 2 })

  def show
    anamnese = self.attributes
    anamnese.store(:patient, self.patient)
    anamnese.store(:therapist, self.therapist)
    anamnese
  end

  def allowed?(profile = User.current.profile)
    return self.therapist_id == profile.id if profile.therapist?
    return true
  end
end

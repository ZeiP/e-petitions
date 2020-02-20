class PetitionCreatedEmailJob < EmailJob
  self.mailer = PetitionMailer
  self.email = :petition_created
end

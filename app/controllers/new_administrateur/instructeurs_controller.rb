module NewAdministrateur
  class NewAdministrateur::InstructeursController < AdministrateurController
    before_action :retrieve_procedure

    def show
      assign_scope = @procedure.defaut_groupe_instructeur.instructeurs
      not_assign_scope = current_administrateur.instructeurs.where.not(id: assign_scope.ids)
      @instructeurs_not_assign_emails = not_assign_scope.map(&:email)
      @instructeurs_assign = assign_scope
      @instructeurs_not_assign = not_assign_scope
    end

    def filter_emails
      emails = params['emails'].presence || []
      emails = emails.map(&:strip).map(&:downcase)
      _email_to_adds, _bad_emails = emails
        .partition { |email| URI::MailTo::EMAIL_REGEXP.match?(email) }
    end

    def add_instructeurs
      emails_to_add = filter_emails[0]
      bad_emails = filter_emails[1]

      if bad_emails.present?
        flash[:alert] = t('.wrong_address',
          count: bad_emails.count,
          value: bad_emails.join(', '))
      end

      if emails_to_add.present?
        instructeurs = emails_to_add.map do |instructeur_email|
          Instructeur.by_email(instructeur_email) ||
            create_instructeur(instructeur_email)
        end

        if instructeurs.present?
          instructeurs.map do |instructeur|
            instructeur.assign_to_procedure(@procedure)
          end
          flash[:notice] = "Les instructeurs ont bien été affectés"
        end
      end

      redirect_to procedure_instructeurs_path(@procedure)
    end

    def remove_instructeur
      instructeur = Instructeur.find(params[:instructeur_id])
      if instructeur.remove_from_procedure(@procedure)
        flash.notice = "L'instructeur a bien été retiré"
      else
        flash.alert = "L'instructeur a déjà été retiré"
      end

      redirect_to procedure_instructeurs_path(@procedure)
    end

    def create_instructeur(email)
      user = User.create_or_promote_to_instructeur(
        email,
        SecureRandom.hex,
        administrateurs: [current_administrateur]
      )
      user.invite!
      user.instructeur
    end
  end
end

module Instructeurs
  class ArchivesController < InstructeurController
    def index
      @procedure = procedure
      if !@procedure.publiee?
        flash[:alert] = "L'accès aux archives n'est disponible que pour les démarches publiées"
        return redirect_to url_for(@procedure)
      end

      @list_of_months = list_of_months
      @dossiers_termines = @procedure.dossiers.state_termine
      @poids_total = ProcedureArchiveService.poids_total(@dossiers_termines)
      @archives = current_instructeur.archives.where(procedure: procedure)
    end

    def create
      type = params[:type]
      month = Date.strptime(params[:month], '%Y-%m') if params[:month].present?

      ProcedureArchiveService.new(procedure).create_archive(current_instructeur, type, month)

      redirect_to instructeur_archives_path
    end

    def show
      archive = current_instructeur
        .archives
        .find(params[:id])

      redirect_to archive.file.service_url

    rescue ActiveRecord::RecordNotFound
      return head(:forbidden)
    end

    private

    def list_of_months
      months = []
      current_month = procedure.published_at.beginning_of_month
      while current_month < Time.zone.now.end_of_month
        months << current_month
        current_month = current_month.next_month
      end
      months.reverse
    end

    def procedure
      current_instructeur
        .procedures
        .includes(:groupe_instructeurs)
        .find(params[:procedure_id])
    end
  end
end

class ActiveStorage::DownloadableFile
  attr_reader :url

  def initialize(attached)
    if using_local_backend?
      @url = 'file://' + ActiveStorage::Blob.service.path_for(attached.key)
    else
      @url = attached.service_url
    end
  end

  def self.create_list_from_dossier(dossier)
    pjs = PiecesJustificativesService.liste_pieces_justificatives(dossier)
    pjs.map do |piece_justificative|
      [
        ActiveStorage::DownloadableFile.new(piece_justificative),
        "dossier-#{dossier.id}/#{piece_justificative.filename}"
      ]
    end
  end

  def self.create_attachment_list_from_dossier(dossier)
    pjs = PiecesJustificativesService.liste_pieces_justificatives(dossier)
    pjs.map do |piece_justificative|
      [
        piece_justificative,
        "dossier-#{dossier.id}/#{piece_justificative.filename}"
      ]
    end
  end

  private

  def using_local_backend?
    [:local, :local_test, :test].include?(Rails.application.config.active_storage.service)
  end
end

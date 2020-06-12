describe NewAdministrateur::InstructeursController, type: :controller do
  let(:admin) { create(:administrateur) }

  before(:all) do
    Rails.cache.clear
  end

  before do
    sign_in(admin.user)
  end

  describe 'GET #show' do
    let(:procedure) { create :procedure, administrateur: admin, instructeurs: [instructeur_assigned_1, instructeur_assigned_2] }
    let!(:instructeur_assigned_1) { create :instructeur, email: 'instructeur_1@ministere_a.gouv.fr', administrateurs: [admin] }
    let!(:instructeur_assigned_2) { create :instructeur, email: 'instructeur_2@ministere_b.gouv.fr', administrateurs: [admin] }
    let!(:instructeur_not_assigned_1) { create :instructeur, email: 'instructeur_3@ministere_a.gouv.fr', administrateurs: [admin] }
    let!(:instructeur_not_assigned_2) { create :instructeur, email: 'instructeur_4@ministere_b.gouv.fr', administrateurs: [admin] }
    subject! { get :show, params: { procedure_id: procedure.id } }

    it { expect(response.status).to eq(200) }

    it 'sets the assigned and not assigned instructeurs' do
      expect(assigns(:instructeurs_assign)).to match_array([instructeur_assigned_1, instructeur_assigned_2])
      expect(assigns(:instructeurs_not_assign)).to match_array([instructeur_not_assigned_1, instructeur_not_assigned_2])
      expect(assigns(:instructeurs_not_assign_emails)).to match_array(['instructeur_3@ministere_a.gouv.fr', 'instructeur_4@ministere_b.gouv.fr'])
      expect(assigns(:instructeurs_assign_emails)).to match_array(['instructeur_1@ministere_a.gouv.fr', 'instructeur_2@ministere_b.gouv.fr'])
    end
  end

  describe 'POST #add_instructeurs' do
    let(:procedure) { create :procedure, administrateur: admin }
    let(:emails) { ['instructeur_3@ministere_a.gouv.fr', 'instructeur_4@ministere_b.gouv.fr'] }
    subject { post :add_instructeurs, params: { emails: emails, procedure_id: procedure.id } }

    context 'when all emails are valid' do
      let(:emails) { ['test@b.gouv.fr', 'test2@b.gouv.fr'] }
      it { expect(response.status).to eq(200) }
      it { expect(subject.request.flash[:alert]).to be_nil }
      it { expect(subject.request.flash[:notice]).to be_present }
      it { expect(subject).to redirect_to procedure_instructeurs_path(procedure_id: procedure.id) }
    end

    context 'when there is at least one bad email' do
      let(:emails) { ['badmail', 'instructeur2@gmail.com'] }
      it { expect(response.status).to eq(200) }
      it { expect(subject.request.flash[:alert]).to be_present }
      it { expect(subject.request.flash[:notice]).to be_present }
      it { expect(subject).to redirect_to procedure_instructeurs_path(procedure_id: procedure.id) }
    end

    context 'when the admin wants to assign an instructor who is already assigned on this procedure' do
      let(:emails) { ['instructeur_1@ministere_a.gouv.fr'] }
      it { expect(subject.request.flash[:alert]).to be_present }
      it { expect(subject).to redirect_to procedure_instructeurs_path(procedure_id: procedure.id) }
    end
  end

  describe 'PATCH #remove_instructeur' do
    let(:procedure) { create :procedure, administrateur: admin, instructeurs: [instructeur_assigned_1, instructeur_assigned_2] }
    let!(:instructeur_assigned_1) { create :instructeur, email: 'instructeur_1@ministere_a.gouv.fr', administrateurs: [admin] }
    let!(:instructeur_assigned_2) { create :instructeur, email: 'instructeur_2@ministere_b.gouv.fr', administrateurs: [admin] }
    let!(:instructeur_assigned_3) { create :instructeur, email: 'instructeur_3@ministere_a.gouv.fr', administrateurs: [admin] }
    subject! { get :show, params: { procedure_id: procedure.id } }
    it 'sets the assigned instructeurs' do
      expect(assigns(:instructeurs_assign)).to match_array([instructeur_assigned_1, instructeur_assigned_2])
    end

    context 'when the instructor is assigned to the procedure' do
      subject { patch :remove_instructeur, params: { instructeur_id: instructeur_assigned_1.id, procedure_id: procedure.id } }
      it { expect(subject.request.flash[:notice]).to be_present }
      it { expect(subject.request.flash[:alert]).to be_nil }
      it { expect(response.status).to eq(302) }
      it { expect(subject).to redirect_to procedure_instructeurs_path(procedure_id: procedure.id) }
    end

    context 'when the instructor is not assigned to the procedure' do
      subject { patch :remove_instructeur, params: { instructeur_id: instructeur_assigned_3.id, procedure_id: procedure.id } }
      it { expect(subject.request.flash[:alert]).to be_present }
      it { expect(subject.request.flash[:notice]).to be_nil }
      it { expect(response.status).to eq(302) }
      it { expect(subject).to redirect_to procedure_instructeurs_path(procedure_id: procedure.id) }
    end
  end
end

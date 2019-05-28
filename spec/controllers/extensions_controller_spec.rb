shared_examples 'set attributes and flash' do
  it 'should flash a message on success' do
    expect_any_instance_of(ExtensionsController).to receive(:flash_now).with(:success, anything)
    post_as admin, :create_or_update, params: params
  end
  it 'should flash a message on error' do
    expect_any_instance_of(ExtensionsController).to receive(:flash_now).with(:error, anything)
    params[:grouping_id] = nil
    post_as admin, :create_or_update, params: params
  end
  describe 'it should update the attibute:' do
    before :each do
      post_as admin, :create_or_update, params: params
      extension.reload
    end
    it 'time_delta' do
      expected_duration = Extension::PARTS.map { |part| params[part].to_i.send(part) }.sum
      expect(extension.time_delta).to eq(expected_duration)
    end
    it 'note' do
      expect(extension.note).to eq(params[:note])
    end
    it 'apply_penalty' do
      expect(extension.apply_penalty).to eq(params[:penalty])
    end
  end
end

describe ExtensionsController do
  describe 'as an admin' do
    let(:admin) { create :admin }
    let(:grouping) { create :grouping }
    describe '#create_or_update' do
      context 'and extension exists' do
        let(:extension) { create :extension, grouping: grouping }
        let(:params) do
          parts = extension.to_parts
          {
            grouping_id: grouping.id,
            weeks: parts[:weeks] + 1,
            days: parts[:days] + 1,
            hours: parts[:hours] + 1,
            note: 'something',
            penalty: true
          }
        end
        it 'should not create a new extension' do
          extension # make sure the object is created before the call
          expect { post_as admin, :create_or_update, params: params }.to_not change { Extension.count }
        end
        include_examples 'set attributes and flash'
      end
      context 'and extension does not exist' do
        let(:extension) { Extension.find_by_grouping_id(grouping.id) }
        let(:params) do
          {
            grouping_id: grouping.id,
            weeks: rand(1..10),
            days: rand(1..10),
            hours: rand(1..10),
            note: 'something',
            penalty: true
          }
        end
        it 'should create a new extension' do
          expect { post_as admin, :create_or_update, params: params }.to change { Extension.count }.by(1)
        end
        include_examples 'set attributes and flash'
      end
    end
    describe '#delete_by_grouping' do
      context 'and the extension exists' do
        let(:extension) { create :extension, grouping: grouping }
        it 'should delete the extension' do
          extension # make sure the object is created before the call
          expect do
            post_as admin, :delete_by_grouping, params: {grouping_id: grouping.id}
          end.to change { Extension.count }.by(-1)
        end
        it 'should flash an success on success' do
          extension # make sure the object is created before the call
          expect_any_instance_of(ExtensionsController).to receive(:flash_now).with(:success, anything)
          post_as admin, :delete_by_grouping, params: {grouping_id: grouping.id}
        end
        it 'should flash an error on error' do
          expect_any_instance_of(ExtensionsController).to receive(:flash_now).with(:error, anything)
          post_as admin, :delete_by_grouping, params: {grouping_id: grouping.id}
        end
      end
    end
  end
end

describe RubricCriterion do
  let(:criterion_factory_name) { :rubric_criterion }

  context 'A rubric criterion model passes criterion tests' do
    it_behaves_like 'a criterion'
  end

  describe '#update_levels' do
    # At creation, rubric already has 5 levels
    let(:rubric) { create(:rubric_criterion) }

    context 'when the properties with uniqueness validations are changed in a way
that two properties A and B have switched values' do
      context 'when the names are changed and the marks are not changed' do
        it 'updates the associated levels if all the levels after update will have unique names' do
          level0_mark, level0_name, level0_id = rubric.levels[0].mark, rubric.levels[0].name, rubric.levels[0].id
          level1_mark, level1_name, level1_id = rubric.levels[1].mark, rubric.levels[1].name, rubric.levels[1].id

          params = {
            '0' => { mark: level0_mark, name: level1_name, id: level0_id },
            '1' => { mark: level1_mark, name: level0_name, id: level1_id }
          }
          rubric.update_levels(params)

          expect(rubric.levels.find_by(id: level0_id).name).to eq(level1_name)
          expect(rubric.levels.find_by(id: level1_id).name).to eq(level0_name)
        end
      end

      context 'when the marks are changed and the names are not changed' do
        it 'updates the associated levels if all the levels after update will have unique marks' do
          level0_mark, level0_name, level0_id = rubric.levels[0].mark, rubric.levels[0].name, rubric.levels[0].id
          level1_mark, level1_name, level1_id = rubric.levels[1].mark, rubric.levels[1].name, rubric.levels[1].id

          params = {
            '0' => { mark: level1_mark, name: level0_name, id: level0_id },
            '1' => { mark: level0_mark, name: level1_name, id: level1_id }
          }
          rubric.update_levels(params)

          expect(rubric.levels.find_by(id: level0_id).mark).to eq(level1_mark)
          expect(rubric.levels.find_by(id: level1_id).mark).to eq(level0_mark)
        end
      end

      context 'when both the marks and the names are changed' do
        it 'updates the associated levels if all the levels after update will have unique marks' do
          level0_mark, level0_name, level0_id = rubric.levels[0].mark, rubric.levels[0].name, rubric.levels[0].id
          level1_mark, level1_name, level1_id = rubric.levels[1].mark, rubric.levels[1].name, rubric.levels[1].id

          params = {
            '0' => { mark: level1_mark, name: level1_name, id: level0_id },
            '1' => { mark: level0_mark, name: level0_name, id: level1_id }
          }
          rubric.update_levels(params)

          expect(rubric.levels.find_by(id: level0_id).mark).to eq(level1_mark)
          expect(rubric.levels.find_by(id: level1_id).mark).to eq(level0_mark)
          expect(rubric.levels.find_by(id: level0_id).name).to eq(level1_name)
          expect(rubric.levels.find_by(id: level1_id).name).to eq(level0_name)
        end
      end
    end

    context 'when the properties with uniqueness validations are changed in a way that the validation is be violated' do
      context 'when the names are changed and the marks are not changed' do
        it 'does not update associated levels' do
          level0_mark, level0_id = rubric.levels[0].mark, rubric.levels[0].id
          level1_mark, level1_name, level1_id = rubric.levels[1].mark, rubric.levels[1].name, rubric.levels[1].id

          params = {
            '0' => { name: level1_name, mark: level0_mark, id: level0_id },
            '1' => { name: level1_name, mark: level1_mark, id: level1_id }
          }
          level0_before = rubric.levels.find_by(id: level0_id)
          level1_before = rubric.levels.find_by(id: level1_id)
          rubric.update_levels(params)

          expect(rubric.levels.find_by(id: level0_id)).to eq(level0_before)
          expect(rubric.levels.find_by(id: level1_id)).to eq(level1_before)
        end
      end

      context 'when the marks are changed and the names are not changed' do
        it 'does not update associated levels' do
          level0_name, level0_id = rubric.levels[0].name, rubric.levels[0].id
          level1_mark, level1_name, level1_id = rubric.levels[1].mark, rubric.levels[1].name, rubric.levels[1].id

          params = {
            '0' => { name: level0_name, mark: level1_mark, id: level0_id },
            '1' => { name: level1_name, mark: level1_mark, id: level1_id }
          }
          level0_before = rubric.levels.find_by(id: level0_id)
          level1_before = rubric.levels.find_by(id: level1_id)
          rubric.update_levels(params)

          expect(rubric.levels.find_by(id: level0_id)).to eq(level0_before)
          expect(rubric.levels.find_by(id: level1_id)).to eq(level1_before)
        end
      end

      context 'when both the marks and the names are changed' do
        it 'does not update associated levels' do
          level0_id = rubric.levels[0].id
          level1_mark, level1_name, level1_id = rubric.levels[1].mark, rubric.levels[1].name, rubric.levels[1].id

          params = {
            '0' => { name: level1_name, mark: level1_mark, id: level0_id },
            '1' => { name: level1_name, mark: level1_mark, id: level1_id }
          }
          level0_before = rubric.levels.find_by(id: level0_id)
          level1_before = rubric.levels.find_by(id: level1_id)
          rubric.update_levels(params)

          expect(rubric.levels.find_by(id: level0_id)).to eq(level0_before)
          expect(rubric.levels.find_by(id: level1_id)).to eq(level1_before)
        end
      end
    end
  end

  context 'A good rubric criterion model' do
    before(:each) do
      @rubric = create(:rubric_criterion)
    end

    it { is_expected.to belong_to(:assignment) }
    it { is_expected.to validate_numericality_of(:max_mark) }
    it { is_expected.to validate_presence_of(:max_mark) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:levels) }
    it { is_expected.to have_one(:course) }

    it 'rounds weights that have more than 1 significant digits' do
      expect(RubricCriterion.count).to be > 0
      criterion = RubricCriterion.first
      criterion.max_mark = 0.5555555555
      criterion.save
      expect(criterion.max_mark).to eq 0.6
    end

    it 'finds a mark for a specific rubric and result' do
      assignment = create(:assignment)
      rubric = create(:rubric_criterion, assignment: assignment)
      grouping = create(:grouping, assignment: assignment)
      submission = create(:submission, grouping: grouping)
      incomplete_result = create(:incomplete_result, submission: submission)

      mark = rubric.marks.where(result_id: incomplete_result.id).first
      expect(mark).to_not be_nil
      expect(mark.mark).to be_nil
    end

    it 'sets default levels' do
      assignment = create(:assignment)
      rubric = create(:rubric_criterion, assignment: assignment)
      rubric.levels.delete_all
      rubric.set_default_levels
      levels = rubric.levels
      expect(levels[0].name).to eq(I18n.t('rubric_criteria.defaults.level_0'))
      expect(levels[1].name).to eq(I18n.t('rubric_criteria.defaults.level_1'))
      expect(levels[2].name).to eq(I18n.t('rubric_criteria.defaults.level_2'))
      expect(levels[3].name).to eq(I18n.t('rubric_criteria.defaults.level_3'))
      expect(levels[4].name).to eq(I18n.t('rubric_criteria.defaults.level_4'))
      expect(levels[0].mark).to eq(0)
      expect(levels[1].mark).to eq(1)
      expect(levels[2].mark).to eq(2)
      expect(levels[3].mark).to eq(3)
      expect(levels[4].mark).to eq(4)
    end
  end

  context 'from an assignment without criteria' do
    before(:each) do
      @assignment = create(:assignment)
    end

    context 'when parsing a CSV file' do
      describe 'raise csv line error on an empty row' do
        it 'raises' do
          expect do
            RubricCriterion.create_or_update_from_csv_row([], @assignment)
          end.to raise_error CsvInvalidLineError
        end
      end
    end

    context 'when parsing a CSV file' do
      describe 'raise csv line error on a 1 element row' do
        it 'raises' do
          expect do
            RubricCriterion.create_or_update_from_csv_row(%w[name], @assignment)
          end.to raise_error CsvInvalidLineError
        end
      end
    end

    context 'when parsing a CSV file' do
      describe 'raise csv line error on a 2 element row' do
        it 'raises' do
          expect do
            RubricCriterion.create_or_update_from_csv_row(%w[name 1.0], @assignment)
          end.to raise_error CsvInvalidLineError
        end
      end
    end

    context 'when parsing a CSV file' do
      describe 'raise csv line error on rows with elements without names for every criterion' do
        row = %w[name 1.0]
        levels = 5
        (0..levels).each do |i|
          row << "name#{i}"
          it 'raises' do
            expect do
              RubricCriterion.create_or_update_from_csv_row(row, @assignment)
            end.to raise_error ArgumentError
          end
        end
      end
    end

    context 'when parsing a CSV file' do
      describe 'raise csv line error on a row with an invalid weight' do
        row = %w[name max_mark l0 l1 l2 l3 l4]
        it 'raises' do
          expect do
            RubricCriterion.create_or_update_from_csv_row(row, @assignment)
          end.to raise_error ArgumentError
        end
      end
    end
  end

  context 'from an assignment without criteria' do
    before(:each) do
      @assignment = create(:assignment)
    end

    context 'and the row is valid' do
      before(:each) do
        # we'll need a valid assignment for those cases.
        @assignment = create(:assignment)
        row = ['criterion 5']
        rubric_levels = 5
        # order is name, number, description, mark
        (0..rubric_levels - 1).each do |i|
          row << "name#{i}"
          # ...containing commas and quotes in the descriptions
          row << "description#{i} with comma (,) and \"\"quotes\"\""
          row << i + 10
        end
        @csv_base_row = row
      end

      context 'and there is an existing rubric criterion with the same name' do
        before(:each) do
          @criterion = create(:rubric_criterion, assignment: @assignment)
          @criterion.levels.delete_all
          @criterion.set_default_levels
          # 'criterion 5' is the name used in the criterion held
          # in @csv_base_row - but they use different level names/descriptions.
          # I'll use the defaults here, and see if I can overwrite with
          # @csv_base_row.
          @criterion.name = 'criterion 5'
          @criterion.assignment = @assignment
          @criterion.position = @assignment.next_criterion_position
          @criterion.max_mark = 5.0
          expect(@criterion.save)
        end

        context 'allow a criterion with the same name to overwrite' do
          it 'not raise error' do
            names = ['Very Poor', 'Weak', 'Passable', 'Good', 'Excellent']
            row = ['criterion 5']
            # order is name, number, description, mark
            @criterion.levels.size.times do |i|
              row << names[i]
              # ...containing commas and quotes in the descriptions
              row << "new description number #{i}"
              row << i + 0.5
            end

            RubricCriterion.create_or_update_from_csv_row(row, @assignment)
            @criterion.reload
            levels = @criterion.levels
            expect(levels.length).to eq(5)
            levels.size.times do |i|
              expect(names[i]).to eq(levels[i].name)
              expect("new description number #{i}").to eq(levels[i].description)
              expect(i + 0.5).to eq(levels[i].mark)
            end
          end
        end

        context 'allow a criterion with the same name to add levels and destroy existing levels' do
          it 'not raise error' do
            RubricCriterion.create_or_update_from_csv_row(@csv_base_row, @assignment)
            @criterion.reload
            levels = @criterion.levels
            expect(levels.order(mark: :asc).first.mark).to eq(10)
            expect(levels.order(mark: :asc).last.mark).to eq(14)
            expect('name4').to eq(levels.order(mark: :asc).last.name)
            expect(levels.length).to eq(5)
          end
        end

        context 'allow a criterion with the same name to update some levels' do
          it 'not raise error' do
            new_csv_row = @csv_base_row[0..9]
            new_csv_row[1] = 'Very Poor'
            RubricCriterion.create_or_update_from_csv_row(new_csv_row, @assignment)
            @criterion.reload
            levels = @criterion.levels
            expect(levels.order(mark: :asc).first.mark).to eq(10)
            expect(levels.order(mark: :asc).last.mark).to eq(12)
            expect('Very Poor').to eq(levels.order(mark: :asc).first.name)
            expect(levels.length).to eq(3)
          end
        end
      end
    end
  end

  context 'A rubric criteria with levels' do
    before(:each) do
      @criterion = create(:rubric_criterion)
    end

    context 'has basic levels functionality' do
      describe 'can add levels' do
        it 'not raise error' do
          expect(@criterion.levels.length).to eq(5)
          @criterion.levels.create(name: 'New level', description: 'Description for level', mark: '5')
          @criterion.levels.create(name: 'New level 2', description: 'Description for level 2', mark: '6')
          expect(@criterion.levels.length).to eq(7)
        end
      end

      describe 'can delete levels' do
        it 'not raise error' do
          expect(@criterion.levels.length).to eq(5)
          @criterion.levels.destroy_by(mark: 0)
          @criterion.levels.destroy_by(mark: 1)
          @criterion.levels.reload
          expect(@criterion.levels.length).to eq(3)
        end
      end

      describe 'can edit levels' do
        it 'not raise error' do
          @criterion.levels[0].update(name: 'Custom Level', description: 'Custom Description', mark: 10.0)
          @criterion.levels.reload
          expect(@criterion.levels[@criterion.levels.length - 1].mark).to eq(10)
          expect(@criterion.levels[@criterion.levels.length - 1].name).to eq('Custom Level')
          expect(@criterion.levels[@criterion.levels.length - 1].description).to eq('Custom Description')
        end
      end

      describe 'deleting a rubric criterion deletes all levels' do
        it 'not raise error' do
          @criterion.destroy
          expect(@criterion.destroyed?).to eq true
          expect(@criterion.levels).to be_empty
        end
      end

      describe 'when finding a level closest to a mark value' do
        it 'finds the level with the value closest to a given mark when the value is greater' do
          criterion = create(:rubric_criterion)
          expect(criterion.level_with_mark_closest_to(1.17).mark).to eq 1
        end

        it 'finds the level with the value closest to a given mark when the value is lesser' do
          criterion = create(:rubric_criterion)
          expect(criterion.level_with_mark_closest_to(1.77).mark).to eq 2
        end
      end
    end

    context 'when scaling max mark' do
      it 'can scale level marks up' do
        expect(@criterion.levels[1].mark).to eq(1.0)
        @criterion.update!(max_mark: 8.0)
        expect(@criterion.levels[1].mark).to eq(2.0)
      end
      it 'scale level marks down' do
        expect(@criterion.levels[1].mark).to eq(1.0)
        @criterion.update!(max_mark: 2.0)
        expect(@criterion.levels[1].mark).to eq(0.5)
      end
      it 'does not scale level marks that have been manually changed' do
        expect(@criterion.levels[1].mark).to eq(1.0)
        @criterion.levels[1].mark = 3
        @criterion.update!(max_mark: 8.0)
        expect(@criterion.levels[1].mark).to eq(3.0)
      end
    end

    context 'editing levels edits marks' do
      before(:each) do
        3.times { create(:submission, grouping: create(:grouping, assignment: @criterion.assignment)) }
        @criterion.marks.first.update(mark: 0)
        @criterion.marks.second.update(mark: 1)
        @criterion.marks.third.update(mark: 1)
      end

      context 'updating level updates respective mark' do
        describe 'updates a single mark' do
          it 'not raise error' do
            @criterion.levels.find_by(mark: 0).update(mark: 0.5)
            expect(@criterion.marks.where(mark: 0.5).size).to eq 1
          end
        end

        describe 'updates multiple marks' do
          it 'not raise error' do
            @criterion.levels.find_by(mark: 1).update(mark: 0.5)
            expect(@criterion.marks.where(mark: 0.5).size).to eq 2
          end
        end
      end

      context 'deleting level updates mark to nil' do
        describe 'updates a single mark' do
          it 'not raise error' do
            @criterion.levels.find_by(mark: 0).destroy
            expect(@criterion.marks.where(mark: nil).size).to eq 1
          end
        end

        describe 'deleting level updates multiple marks to nil' do
          it 'not raise error' do
            @criterion.levels.find_by(mark: 1).destroy
            expect(@criterion.marks.where(mark: nil).size).to eq 2
          end
        end
      end
    end

    context 'validations work properly' do
      context 'when a result is released' do
        before(:each) do
          @marks = @criterion.marks
          results = []
          3.times do
            submission = create(:submission, grouping: create(:grouping, assignment: @criterion.assignment))
            results << submission.current_result
          end
          @marks.create(mark: 0, result: results[0])
          @marks.create(mark: 1, result: results[1])
          @marks.create(mark: 1, result: results[2])
          results.each do |result|
            # have to release to students after or else cannot assign marks
            result.released_to_students = true
            result.save
          end
        end
        describe 'levels can\'t be updated' do
          it 'not raise error' do
            expect(@criterion.levels[0].update(mark: 1.5)).to be false
          end
        end
        describe 'rubric criteria can\'t be updated' do
          it 'not raise error' do
            expect(@criterion.update(max_mark: 10)).to be false
          end
        end
      end
    end
  end
end

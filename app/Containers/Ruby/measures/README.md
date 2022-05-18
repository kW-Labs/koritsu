# Koritsu Measures

## Adding A New Measure
1. Edit `create_sce_measures.rb` too add new hash to `measures_to_add` array with measure info
2. Run `create_sce_measures.rb` to create measure files
3. Write measure code and tests
4. Update measure xml by running the following (from this directory): 

  ```openstudio measure --update /measure_dirname```

5. Create a new entry in koritsu-www/app/Containers/Koritsu/WebApp/UI/WEB/Views/src/schema/alternative_measures.json with:
  - "text": measure clas sname (e.g. "SCE Measure')
  - "value": measure dirname (e.g. 'sce_measure')
  - "model_dependent": true/false, depending on whether measure has model-dependent arguments

6. Create and save an empty model to the current working dir:

``` openstudio -e "OpenStudio::Model::Model.new.save('in.osm',true)" ```

7. Create measure json and save to schema folder

``` openstudio create_measure_spec.rb ```

8. Commit new files
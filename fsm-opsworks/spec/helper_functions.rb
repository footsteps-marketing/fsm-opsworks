def stub_search_result(data_bag, result)
  query = instance_double("Chef::Search::Query")
  expect(query).to receive(:search).with(data_bag)
    .and_return(result)
    
  query_class = class_double("Chef::Search::Query")
    .as_stubbed_const(:transfer_nested_constants => true)
  expect(query_class).to receive(:new).and_return(query)
end

Feature: Migrations that contain nodes with "reference" or "references properties

  Background:
    Given using no content dimensions
    And using the following node types:
    """yaml
    'Neos.Neos:Site': {}
    'Some.Package:Homepage':
      superTypes:
        'Neos.Neos:Site': true
    'Some.Package:SomeNodeType':
      properties:
        'text':
          type: string
          defaultValue: 'My default text'
        'ref':
          type: reference
        'refs':
          type: references
    'Some.Package:SomeOtherNodeType':
      properties:
        'text':
          type: string
    """
    And using identifier "default", I define a content repository
    And I am in content repository "default"

  Scenario: Two nodes with references
    When I have the following node data rows:
      | Identifier | Path          | Node Type                      | Properties                                |
      | sites      | /sites        | unstructured                   |                                           |
      | site       | /sites/site   | Some.Package:Homepage          |                                           |
      | a          | /sites/site/a | Some.Package:SomeNodeType      | {"text": "This is a", "ref": "b"}         |
      | b          | /sites/site/b | Some.Package:SomeOtherNodeType | {"text": "This is b"}                     |
      | c          | /sites/site/c | Some.Package:SomeNodeType      | {"text": "This is c", "refs": ["a", "b"]} |
    And I run the event migration
    Then I expect the following events to be exported
      | Type                                | Payload                                                                                                                                                                                                               |
      | RootNodeAggregateWithNodeWasCreated | {"nodeAggregateId": "sites"}                                                                                                                                                                                          |
      | NodeAggregateWithNodeWasCreated     | {"nodeAggregateId": "site"}                                                                                                                                                                                           |
      | NodeAggregateWithNodeWasCreated     | {"nodeAggregateId": "a"}                                                                                                                                                                                              |
      | NodeAggregateWithNodeWasCreated     | {"nodeAggregateId": "b"}                                                                                                                                                                                              |
      | NodeAggregateWithNodeWasCreated     | {"nodeAggregateId": "c"}                                                                                                                                                                                              |
      | NodeReferencesWereSet               | {"nodeAggregateId":"a","affectedSourceOriginDimensionSpacePoints":[[]],"references":[{"referenceName": "ref", "references": [{"target":"b"}]}]}                                                      |
      | NodeReferencesWereSet               | {"nodeAggregateId":"c","affectedSourceOriginDimensionSpacePoints":[[]],"references":[{"referenceName": "refs", "references": [{"target":"a"},{"target":"b"}]}]} |


  Scenario: Node with references in one dimension
    Given I change the content dimensions in content repository "default" to:
      | Identifier | Default | Values     | Generalizations |
      | language   | en      | en, de, ch | ch->de          |
    When I have the following node data rows:
      | Identifier | Path          | Node Type                 | Dimension Values     | Properties                                |
      | sites      | /sites        | unstructured              |                      |                                           |
      | site       | /sites/site   | Some.Package:Homepage     | {"language": ["en"]} |                                           |
      | site       | /sites/site   | Some.Package:Homepage     | {"language": ["de"]} |                                           |
      | a          | /sites/site/a | Some.Package:SomeNodeType | {"language": ["en"]} | {"text": "This is a", "ref": "b"}         |
      | b          | /sites/site/b | Some.Package:SomeNodeType | {"language": ["de"]} | {"text": "This is b", "ref": "a"}         |
      | c          | /sites/site/c | Some.Package:SomeNodeType | {"language": ["ch"]} | {"text": "This is c", "refs": ["a", "b"]} |
    And I run the event migration
    Then I expect the following events to be exported
      | Type                                | Payload                                                                                                                                                                                                                               |
      | RootNodeAggregateWithNodeWasCreated | {"nodeAggregateId": "sites"}                                                                                                                                                                                                          |
      | NodeAggregateWithNodeWasCreated     | {"nodeAggregateId": "site"}                                                                                                                                                                                                           |
      | NodePeerVariantWasCreated           | {}                                                                                                                                                                                                                                    |
      | NodeAggregateWithNodeWasCreated     | {"nodeAggregateId": "a"}                                                                                                                                                                                                              |
      | NodeAggregateWithNodeWasCreated     | {"nodeAggregateId": "b"}                                                                                                                                                                                                              |
      | NodeAggregateWithNodeWasCreated     | {"nodeAggregateId": "c"}                                                                                                                                                                                                              |
      | NodeReferencesWereSet               | {"nodeAggregateId":"a","affectedSourceOriginDimensionSpacePoints":[{"language": "en"}],"references":[{"referenceName":"ref","references":[{"target":"b"}]}]}                                                      |
      | NodeReferencesWereSet               | {"nodeAggregateId":"b","affectedSourceOriginDimensionSpacePoints":[{"language": "de"}],"references":[{"referenceName":"ref","references":[{"target":"a"}]}]}                                                      |
      | NodeReferencesWereSet               | {"nodeAggregateId":"c","affectedSourceOriginDimensionSpacePoints":[{"language": "ch"}],"references":[{"referenceName":"refs","references":[{"target":"a"},{"target":"b"}]}]} |

  Scenario: A reference emptied in a variant is cleared instead of keeping the copied target
    # the "en" peer variant is created as a copy of its "de" source including all reference relations.
    # an emptied reference produces no entry in the variant's row, so the copied relation must be
    # cleared explicitly via a reference entry without targets.
    Given I change the content dimensions in content repository "default" to:
      | Identifier | Default | Values     | Generalizations |
      | language   | en      | en, de, ch | ch->de          |
    When I have the following node data rows:
      | Identifier | Path          | Node Type                 | Dimension Values     | Properties   |
      | sites      | /sites        | unstructured              |                      |              |
      | site       | /sites/site   | Some.Package:Homepage     | {"language": ["de"]} |              |
      | site       | /sites/site   | Some.Package:Homepage     | {"language": ["en"]} |              |
      | a          | /sites/site/a | Some.Package:SomeNodeType | {"language": ["de"]} | {"ref": "b"} |
      | a          | /sites/site/a | Some.Package:SomeNodeType | {"language": ["en"]} | {"ref": ""}  |
      | b          | /sites/site/b | Some.Package:SomeNodeType | {"language": ["de"]} |              |
    And I run the event migration
    Then I expect the following events to be exported
      | Type                                | Payload                                                                                                                                      |
      | RootNodeAggregateWithNodeWasCreated | {"nodeAggregateId": "sites"}                                                                                                                 |
      | NodeAggregateWithNodeWasCreated     | {"nodeAggregateId": "site", "originDimensionSpacePoint": {"language": "de"}}                                                                 |
      | NodePeerVariantWasCreated           | {"nodeAggregateId": "site", "sourceOrigin": {"language": "de"}, "peerOrigin": {"language": "en"}}                                            |
      | NodeAggregateWithNodeWasCreated     | {"nodeAggregateId": "a", "originDimensionSpacePoint": {"language": "de"}}                                                                    |
      | NodePeerVariantWasCreated           | {"nodeAggregateId": "a", "sourceOrigin": {"language": "de"}, "peerOrigin": {"language": "en"}}                                               |
      | NodeAggregateWithNodeWasCreated     | {"nodeAggregateId": "b"}                                                                                                                     |
      | NodeReferencesWereSet               | {"nodeAggregateId":"a","affectedSourceOriginDimensionSpacePoints":[{"language": "de"}],"references":[{"referenceName":"ref","references":[{"target":"b"}]}]} |
      | NodeReferencesWereSet               | {"nodeAggregateId":"a","affectedSourceOriginDimensionSpacePoints":[{"language": "en"}],"references":[{"referenceName":"ref","references":[]}]}               |

  Scenario: A reference absent from a variant's row is cleared while its own references are kept
    # the "en" peer variant copies the "ref" and "refs" relations from its "de" source. its row sets
    # "refs" itself but does not carry "ref" at all, so the copied "ref" relation must be cleared in
    # the same event that sets the row's own references.
    Given I change the content dimensions in content repository "default" to:
      | Identifier | Default | Values     | Generalizations |
      | language   | en      | en, de, ch | ch->de          |
    When I have the following node data rows:
      | Identifier | Path          | Node Type                 | Dimension Values     | Properties                        |
      | sites      | /sites        | unstructured              |                      |                                   |
      | site       | /sites/site   | Some.Package:Homepage     | {"language": ["de"]} |                                   |
      | site       | /sites/site   | Some.Package:Homepage     | {"language": ["en"]} |                                   |
      | a          | /sites/site/a | Some.Package:SomeNodeType | {"language": ["de"]} | {"ref": "b", "refs": ["b", "c"]}  |
      | a          | /sites/site/a | Some.Package:SomeNodeType | {"language": ["en"]} | {"refs": ["c"]}                   |
      | b          | /sites/site/b | Some.Package:SomeNodeType | {"language": ["de"]} |                                   |
      | c          | /sites/site/c | Some.Package:SomeNodeType | {"language": ["de"]} |                                   |
    And I run the event migration
    Then I expect the following events to be exported
      | Type                                | Payload                                                                                                                                      |
      | RootNodeAggregateWithNodeWasCreated | {"nodeAggregateId": "sites"}                                                                                                                 |
      | NodeAggregateWithNodeWasCreated     | {"nodeAggregateId": "site", "originDimensionSpacePoint": {"language": "de"}}                                                                 |
      | NodePeerVariantWasCreated           | {"nodeAggregateId": "site", "sourceOrigin": {"language": "de"}, "peerOrigin": {"language": "en"}}                                            |
      | NodeAggregateWithNodeWasCreated     | {"nodeAggregateId": "a", "originDimensionSpacePoint": {"language": "de"}}                                                                    |
      | NodePeerVariantWasCreated           | {"nodeAggregateId": "a", "sourceOrigin": {"language": "de"}, "peerOrigin": {"language": "en"}}                                               |
      | NodeAggregateWithNodeWasCreated     | {"nodeAggregateId": "b"}                                                                                                                     |
      | NodeAggregateWithNodeWasCreated     | {"nodeAggregateId": "c"}                                                                                                                     |
      | NodeReferencesWereSet               | {"nodeAggregateId":"a","affectedSourceOriginDimensionSpacePoints":[{"language": "de"}],"references":[{"referenceName":"ref","references":[{"target":"b"}]},{"referenceName":"refs","references":[{"target":"b"},{"target":"c"}]}]} |
      | NodeReferencesWereSet               | {"nodeAggregateId":"a","affectedSourceOriginDimensionSpacePoints":[{"language": "en"}],"references":[{"referenceName":"refs","references":[{"target":"c"}]},{"referenceName":"ref","references":[]}]}                              |

  Scenario: Nodes with properties that are not part of the node type schema (see https://github.com/neos/neos-development-collection/issues/4804)
    When I have the following node data rows:
      | Identifier    | Path             | Node Type             | Properties                 |
      | sites-node-id | /sites           | unstructured          |                            |
      | site-node-id  | /sites/test-site | Some.Package:Homepage | {"unknownProperty": "ref"} |
    And I run the event migration
    Then I expect the following events to be exported
      | Type                                | Payload                              |
      | RootNodeAggregateWithNodeWasCreated | {"nodeAggregateId": "sites-node-id"} |
      | NodeAggregateWithNodeWasCreated     | {"nodeAggregateId": "site-node-id"}  |
    And I expect the following warnings to be logged
      | Skipped node data processing for the property "unknownProperty". The property name is not part of the NodeType schema for the NodeType "Some.Package:Homepage". (Node: site-node-id) |

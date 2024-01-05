/// A type that can be attributed with IPP attributes.
public protocol IppAttributable {
    var attributeGroups: IppAttributeGroups { get set }
}

extension IppRequest: IppAttributable {}
extension IppResponse: IppAttributable {}

public extension IppAttributable {
    /// Accesses the first attribute group with the specified name. If the group does not exist, it is created.

    /// This mostly behaves like a dictionary, but the IPP specification allows for multiple groups with the same name.
    subscript(_ name: IppAttributeGroup.Name) -> IppAttributes {
        _read {
            if let index = attributeGroups.firstIndex(where: { $0.name == name }) {
                yield attributeGroups[index].attributes
            } else {
                yield[:]
            }
        }
        _modify {
            if let index = attributeGroups.firstIndex(where: { $0.name == name }) {
                yield &attributeGroups[index].attributes
            } else {
                var group = IppAttributeGroup(name: name, attributes: [:])
                yield &group.attributes
                attributeGroups.append(group)
            }
        }
    }
}

public extension IppRequest {
    /// Access an attribute in the `operation` group.
    subscript<V>(operation attribute: KeyPath<SemanticModel.Attributes.Operation, SemanticModel.Attribute<V>>) -> V? {
        get {
            self[.operation][(\SemanticModel.Attributes.operation).appending(path: attribute)]
        }
        set {
            self[.operation][(\SemanticModel.Attributes.operation).appending(path: attribute)] = newValue
        }
    }

    /// Access an attribute in the `job` group.
    subscript<V>(job attribute: KeyPath<SemanticModel.Attributes.JobTemplate, SemanticModel.Attribute<V>>) -> V? {
        get {
            self[.job][(\SemanticModel.Attributes.jobTemplate).appending(path: attribute)]
        }
        set {
            self[.job][(\SemanticModel.Attributes.jobTemplate).appending(path: attribute)] = newValue
        }
    }
}

public extension IppResponse {
    /// Access an attribute in the `operation` group.
    subscript<V>(operation attribute: KeyPath<SemanticModel.Attributes.OperationResponse, SemanticModel.Attribute<V>>) -> V? {
        get {
            self[.operation][(\SemanticModel.Attributes.operationResponse).appending(path: attribute)]
        }
        set {
            self[.operation][(\SemanticModel.Attributes.operationResponse).appending(path: attribute)] = newValue
        }
    }

    /// Access an attribute in the `job` group.
    subscript<V>(job attribute: KeyPath<SemanticModel.Attributes.JobDescription, SemanticModel.Attribute<V>>) -> V? {
        get {
            self[.job][(\SemanticModel.Attributes.jobDescription).appending(path: attribute)]
        }
        set {
            self[.job][(\SemanticModel.Attributes.jobDescription).appending(path: attribute)] = newValue
        }
    }
}

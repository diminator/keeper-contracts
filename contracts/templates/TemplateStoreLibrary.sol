pragma solidity 0.5.3;

library TemplateStoreLibrary {

    enum TemplateState { Uninitialized, Proposed, Approved, Revoked }

    struct Template {
        TemplateState state;
        address owner;
        address lastUpdatedBy;
        uint256 blockNumberUpdated;
    }

    struct TemplateList {
        mapping(address => Template) templates;
        address[] templateIds;
    }

    function propose(
        TemplateList storage _self,
        address _id
    )
        internal
        returns (uint size)
    {
        require(
            _self.templates[_id].blockNumberUpdated == 0,
            'Id already exists'
        );
        _self.templates[_id] = Template({
            state: TemplateState.Proposed,
            owner: msg.sender,
            lastUpdatedBy: msg.sender,
            blockNumberUpdated: block.number
        });
        _self.templateIds.push(_id);
        return _self.templateIds.length;
    }

    function approve(
        TemplateList storage _self,
        address _id
    )
        internal
    {
        require(
            _self.templates[_id].state == TemplateState.Proposed,
            'Template not Proposed'
        );
        _self.templates[_id].state = TemplateState.Approved;
        _self.templates[_id].lastUpdatedBy = msg.sender;
        _self.templates[_id].blockNumberUpdated = block.number;
    }

    function revoke(
        TemplateList storage _self,
        address _id
    )
        internal
    {
        require(
            _self.templates[_id].state == TemplateState.Approved,
            'Template not Approved'
        );
        _self.templates[_id].state = TemplateState.Revoked;
        _self.templates[_id].lastUpdatedBy = msg.sender;
        _self.templates[_id].blockNumberUpdated = block.number;
    }
}

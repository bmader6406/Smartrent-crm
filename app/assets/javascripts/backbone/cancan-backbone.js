(function() {
  (function() {
    var root;
    root = this;
    root.Ability = Backbone.Model.extend({
      defaults: function() {
        return {
          rules: [],
          aliased_actions: {
            read: ["index", "show"],
            create: ["new"],
            update: ["edit"]
          }
        };
      },
      initialize: function() {
        if (!_.isEmpty(this.get("rules"))) {
          this.set("rules", _.map(this.get("rules"), function(rule) {
            return new Rule(rule);
          }));
        }
      },
      can: function(action, subject) {
        var match;
        match = _.detect(this.relevant_rules(action, subject), function(rule) {
          return rule.matches_conditions(action, subject);
        }, this);
        if (match) {
          return match.get("base_behavior");
        } else {
          return false;
        }
      },
      cannot: function(action, subject) {
        return !this.can(action, subject);
      },
      set_can: function(action, subject, conditions) {
        this.get("rules").push(new Rule({
          base_behavior: true,
          action: action,
          subject: subject,
          conditions: conditions
        }));
      },
      set_cannot: function(action, subject, conditions) {
        this.get("rules").push(new Rule({
          base_behavior: false,
          action: action,
          subject: subject,
          conditions: conditions
        }));
      },
      alias_action: function(from, target) {
        this.validate_target(target);
        if (!_.isArray(this.get("aliased_actions")[target])) {
          this.get("aliased_actions")[target] = [];
        }
        this.get("aliased_actions")[target] = this.get("aliased_actions")[target].concat(from);
      },
      validate_target: function(target) {
        if (_.chain(this.get("aliased_actions")).values().flatten().include(target).value()) {
          throw new Error("You can't specify target (" + target + ") as alias because it is real action name");
        }
      },
      clear_aliased_actions: function() {
        this.set("aliased_actions", {});
      },
      expand_actions: function(actions) {
        return _.chain(actions).map(function(action) {
          if (this.get("aliased_actions")[action]) {
            return [action].concat(this.expand_actions(this.get("aliased_actions")[action]));
          } else {
            return action;
          }
        }, this).flatten().value();
      },
      relevant_rules: function(action, subject) {
        var reversed_rules;
        reversed_rules = this.get("rules").slice(0);
        return _.select(reversed_rules.reverse(), (function(rule) {
          rule.set("expanded_actions", this.expand_actions(rule.get("actions")));
          return rule.is_relevant(action, subject);
        }), this);
      }
    });
    root.Rule = Backbone.Model.extend({
      initialize: function() {
        if (!this.get("actions") && this.get("action")) {
          this.set("actions", _.flatten([this.get("action")]));
        }
        if (!this.get("subjects") && this.get("subject")) {
          this.set("subjects", _.flatten([this.get("subject")]));
        }
        if (!this.get("conditions")) {
          this.set("conditions", {});
        }
      },
      backbone_class: function(sub) {
        if (sub == null) {
          sub = null;
        }
        return sub != null ? sub.backboneClass : void 0;
      },
      is_relevant: function(action, subject) {
        return this.matches_action(action) && this.matches_subject(subject);
      },
      matches_conditions: function(action, subject) {
        if (_.isObject(this.get("conditions")) && !_.isEmpty(this.get("conditions")) && !this.subject_class(subject)) {
          return this.matches_conditions_hash(subject);
        } else {
          if (_.isEmpty(this.get("conditions"))) {
            return true;
          } else {
            return this.get("base_behavior");
          }
        }
      },
      subject_class: function(subject) {
        if (this.backbone_class(subject)) {
          return true;
        } else {
          return false;
        }
      },
      matches_action: function(action) {
        return _.include(this.get("expanded_actions"), "manage") || _.include(this.get("expanded_actions"), action);
      },
      matches_subject: function(subject) {
        return _.include(this.get("subjects"), "all") || _.include(this.get("subjects"), subject) || this.matches_subject_class(subject);
      },
      matches_subject_class: function(subject) {
        return _.any(this.get("subjects"), (function(_this) {
          return function(sub) {
            var sub_class, subject_class;
            sub_class = _this.backbone_class(sub) || _this.backbone_class(sub.constructor);
            subject_class = _this.backbone_class(subject) || _this.backbone_class(subject.constructor);
            return (sub_class && subject_class && sub_class === subject_class) || sub === subject_class || sub_class === subject;
          };
        })(this));
      },
      matches_conditions_hash: function(subject, conditions) {
        if (!conditions) {
          conditions = this.get("conditions");
        }
        if (_.isEmpty(conditions)) {
          return true;
        } else {
          return _.all(conditions, (function(value, name) {
            var attribute;
            attribute = subject[name];
            if (_.isUndefined(attribute)) {
              attribute = subject.get(name);
            }
            if (_.isObject(value) && !_.isArray(value)) {
              if (_.isArray(attribute)) {
                return _.any(attribute, (function(element) {
                  this.matches_conditions_hash(element, value);
                }), this);
              } else {
                return attribute && this.matches_conditions_hash(attribute, value);
              }
            } else if (_.isArray(value)) {
              return _.include(value, attribute) || _.isEqual(value, attribute);
            } else {
              return attribute === value;
            }
          }), this);
        }
      }
    });
  }).call(this);

}).call(this);

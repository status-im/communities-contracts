## Protocol properties and invariants

Below is a list of all documented properties and invariants of this project that must hold true.

- **Property** - Describes the property of the project / protocol that should ultimately be tested and formaly verified.
- **Type** - Properties are split into 5 main types: **Valid State**, **State Transition**, **Variable Transition**,
  **High-Level Property**, **Unit Test**
- **Risk** - One of **High**, **Medium** and **Low**, depending on the property's risk factor
- **Tested** - Whether this property has been (fuzz) tested

| **Property**                                                              | **Type**            | **Risk** | **Tested** |
| ------------------------------------------------------------------------- | ------------------- | -------- | ---------- |
| Only allows deployment with valid signature                               | Unit test           | High     | Yes        |
| Adds Owner token entry to registry upon deployment                        | Unit test           | Low      | Yes        |
| Only one deployment per account allowed                                   | Unit test           | Medium   | Yes        |
| One and only one owner token address exists in the registry per community | Valid state         | High     | Yes        |
| If deployment registry address changes, sender must be owner              | Variable transition | High     | Yes        |
| If owner token factory address changes, sender must be owner              | Variable transition | High     | Yes        |
| If master token factory address changes, sender must be owner             | Variable transition | High     | Yes        |
| Registry grows as the more accounts perform a deployment                  | High-Level Property | Low      | No         |
